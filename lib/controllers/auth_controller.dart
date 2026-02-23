import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';
import '../core/utils/error_handler.dart';

class AuthController extends GetxController {
  final _supabase = SupabaseService.client;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  bool _needsProfileCompletion = false;

  bool get needsProfileCompletion => _needsProfileCompletion;

  @override
  void onInit() {
    super.onInit();
    _checkAuthState();
  }

  // Check if user is already authenticated
  Future<void> _checkAuthState() async {
    // First check if Supabase has a current session
    // Supabase may have persisted the session despite storage errors
    final user = _supabase.auth.currentUser;
    if (user != null) {
      print('✅ Found existing Supabase session');
      await _loadUserProfile();
      return;
    }

    // Check if there's a session in the auth state
    final session = _supabase.auth.currentSession;
    if (session != null) {
      print('✅ Found session in auth state');
      await _loadUserProfile();
      return;
    }

    // If no session, try to restore from stored tokens (Remember Me)
    // This is a fallback if Supabase's built-in persistence didn't work
    try {
      final tokens = await StorageService.getSessionTokens();
      final accessToken = tokens['access_token'];
      final rememberMe = await StorageService.getRememberMe();

      if (rememberMe && accessToken != null) {
        print('🔵 Attempting to restore session from stored tokens...');
        try {
          await _supabase.auth.setSession(accessToken);
          print('✅ Session restored successfully from stored tokens');
          await _loadUserProfile();
        } catch (e) {
          print('⚠️ Failed to restore session from tokens: $e');
          // Clear invalid tokens
          try {
            await StorageService.clearUserSession();
          } catch (clearError) {
            print('⚠️ Could not clear session: $clearError');
          }
        }
      } else {
        print('🔵 No Remember Me tokens found');
      }
    } catch (e) {
      // Storage errors are non-fatal - Supabase might still have a session
      print('⚠️ Error checking stored session (non-fatal): $e');
    }
  }

  // Sign in with student ID or email and password
  Future<bool> signIn(
      String identifier, // Can be student ID or email
      String password, {
        bool rememberMe = false,
      }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔵 Starting sign in for: $identifier');

      String email;

      // Check if identifier is an email (contains @)
      if (identifier.contains('@')) {
        // It's an email, use it directly
        email = identifier;
        print('🔵 Identifier is an email: $email');
      } else {
        // It's a student ID, look up email from database
        print('🔵 Identifier is a student ID, looking up profile...');
        final profileResponse = await _supabase
            .from('user_profiles')
            .select('*')
            .eq('student_id', identifier)
            .maybeSingle();

        if (profileResponse == null) {
          errorMessage.value =
              'Student ID not found. If you have not registered yet, please sign up using your email address first.';
          print('❌ Student ID not found in database');
          return false;
        }

        final profile = profileResponse;
        email = profile['email'] as String;
        final profileId = profile['id'];

        print('✅ Student found: ${profile['full_name']} ($email)');

        // Check if profile is linked to an auth user
        if (profileId == null) {
          errorMessage.value =
          'This student ID is not registered yet. Please sign up first.';
          print('❌ Student profile not linked to auth user');
          return false;
        }
      }

      // Sign in with email
      print('🔵 Signing in with email: $email');
      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (authError) {
        // Check if it's a storage error (non-fatal) or actual auth error
        final errorStr = authError.toString();
        if (errorStr.contains('shared_preferences') ||
            errorStr.contains('flutter_secure_storage') ||
            errorStr.contains('LateInitializationError')) {
          // Storage error - check if auth actually succeeded
          print('⚠️ Storage error during sign in (non-fatal): $authError');
          final currentUser = _supabase.auth.currentUser;
          if (currentUser != null && currentUser.email == email) {
            // Auth succeeded despite storage error - continue
            print('✅ Sign in succeeded despite storage error');
          } else {
            // Actual auth failure
            errorMessage.value = 'Invalid password. Please try again.';
            return false;
          }
        } else {
          // Actual auth error - check if it's invalid credentials
          if (errorStr.contains('Invalid login credentials') ||
              errorStr.contains('Invalid password')) {
            errorMessage.value = 'Invalid password. Please try again.';
            return false;
          }
          // Other auth errors
          rethrow;
        }
      }

      // Check if user is authenticated (even if storage failed)
      final authenticatedUser = _supabase.auth.currentUser;
      if (authenticatedUser != null && authenticatedUser.email == email) {
        // Save Remember Me preference
        try {
          await StorageService.setRememberMe(rememberMe);
        } catch (e) {
          print('⚠️ Failed to save Remember Me preference: $e');
        }

        // If Remember Me is checked, save session tokens
        if (rememberMe) {
          try {
            final session = _supabase.auth.currentSession;
            if (session != null) {
              await StorageService.saveSessionTokens(
                session.accessToken,
                session.refreshToken ?? '',
              );
              print('✅ Session tokens saved for Remember Me');
            }
          } catch (tokenError) {
            print('⚠️ Failed to save session tokens: $tokenError');
            // Continue anyway
          }
        } else {
          // Clear tokens if Remember Me is not checked
          try {
            final tokens = await StorageService.getSessionTokens();
            if (tokens['access_token'] != null) {
              await StorageService.removeKey('access_token');
              await StorageService.removeKey('refresh_token');
            }
          } catch (e) {
            print('⚠️ Error clearing tokens: $e');
          }
        }

        // Try to save session, but don't fail if it errors
        try {
          await SupabaseService.saveUserSession(authenticatedUser.id, email);
          print('✅ Session saved');
        } catch (sessionError) {
          print('⚠️ Session save warning (non-fatal): $sessionError');
          // Continue anyway - user is authenticated
        }

        // Load user profile
        try {
          await _loadUserProfile();
          print('✅ User profile loaded');
        } catch (profileError) {
          print('⚠️ Profile load warning (non-fatal): $profileError');
          // Continue anyway - user is authenticated
        }

        print('✅ Sign in successful');
        return true;
      } else {
        errorMessage.value = 'Sign in failed. Please try again.';
        return false;
      }
    } catch (e) {
      ErrorHandler.logError(e, context: 'Sign in');
      errorMessage.value = ErrorHandler.getUserFriendlyMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Sign up with student ID or email and password
  Future<bool> signUp(String identifier, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      _needsProfileCompletion = false;

      print('🔵 Starting sign up for: $identifier');

      String email;
      String? fullName;
      String? studentId;
      Map<String, dynamic>? profileResponse;

      // Check if identifier is an email (contains @)
      if (identifier.contains('@')) {
        // It's an email, check if user exists in profiles
        email = identifier;
        print('🔵 Identifier is an email: $email');

        profileResponse = await _supabase
            .from('user_profiles')
            .select('*')
            .eq('email', email)
            .maybeSingle();

        if (profileResponse != null) {
          fullName = profileResponse['full_name'] as String?;
          studentId = profileResponse['student_id'] as String?;

          // Check if profile is already linked to an auth user
          if (profileResponse['id'] != null) {
            errorMessage.value =
            'This email is already registered. Please sign in instead.';
            print('❌ Email already linked to auth user');
            return false;
          }
        }
        // If profile doesn't exist, user needs to complete profile
      } else {
        // It's a student ID, look up profile from database
        print('🔵 Identifier is a student ID, looking up profile...');
        profileResponse = await _supabase
            .from('user_profiles')
            .select('*')
            .eq('student_id', identifier)
            .maybeSingle();

        if (profileResponse == null) {
          errorMessage.value =
              'Student ID not found in our database. Since you are registering for the first time, please use your email address to sign up.';
          print('❌ Student ID not found in database');
          return false;
        }

        email = profileResponse['email'] as String;
        fullName = profileResponse['full_name'] as String;
        studentId = identifier;

        print('✅ Student found: $fullName ($email)');

        // Check if profile is already linked to an auth user
        if (profileResponse['id'] != null) {
          errorMessage.value =
          'This student ID is already registered. Please sign in instead.';
          print('❌ Student profile already linked to auth user');
          return false;
        }
      }

      // Step 3: Create auth user with email from profile
      print('🔵 Creating auth user with email: $email');
      AuthResponse response;
      try {
        print('🔵 Attempting sign up via REST API...');
        response = await _signUpViaRestApi(email, password);
        print('🔵 Sign up via REST API completed');
      } catch (e) {
        print('❌ REST API sign up failed: $e');
        // Fallback to SDK method with timeout
        print('🔵 Trying SDK method as fallback...');
        try {
          response = await _supabase.auth
              .signUp(email: email, password: password)
              .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('❌ SDK sign up timeout');
              throw TimeoutException(
                'Sign up timed out. Please check your connection and try again.',
              );
            },
          );
          print('🔵 SDK sign up call completed');
        } catch (sdkError) {
          print('❌ SDK sign up also failed: $sdkError');
          rethrow;
        }
      }

      if (response.user == null) {
        errorMessage.value = 'Failed to create account. Please try again.';
        return false;
      }

      print('✅ Auth user created: ${response.user!.id}');

      // Step 4: Link auth user to existing profile (update profile id)
      print('🔵 Linking auth user to student profile...');
      try {
        // Set session first (required for RLS)
        final session = response.session;
        final refreshToken = session?.refreshToken;
        if (refreshToken != null) {
          try {
            await _supabase.auth
                .setSession(refreshToken)
                .timeout(const Duration(seconds: 5));
            print('✅ Session set');
          } catch (e) {
            print('⚠️ Session set warning (non-fatal): $e');
            // Try to refresh session
            try {
              await _supabase.auth.refreshSession();
              print('✅ Session refreshed');
            } catch (refreshError) {
              print('⚠️ Could not refresh session: $refreshError');
            }
          }
        } else {
          // If no session, try to get current session
          try {
            final currentSession = _supabase.auth.currentSession;
            if (currentSession == null) {
              print('⚠️ No session available - user may need to sign in');
            }
          } catch (e) {
            print('⚠️ Could not check session: $e');
          }
        }

        // Update profile to link with auth user
        if (studentId != null) {
          await _supabase
              .from('user_profiles')
              .update({'id': response.user!.id})
              .eq('student_id', studentId);
          print('✅ Profile linked to auth user');
        } else if (profileResponse != null) {
          // If signing up with email and profile exists, update by email
          await _supabase
              .from('user_profiles')
              .update({'id': response.user!.id})
              .eq('email', email);
          print('✅ Profile linked to auth user');
        } else {
          // Profile doesn't exist - user needs to complete profile
          print('⚠️ Profile not found - user needs to complete profile');
        }
      } catch (linkError) {
        print('❌ Error linking profile: $linkError');
        errorMessage.value =
        'Account created but profile linking failed. Please sign in to complete setup.';
        // Continue anyway - user can sign in and profile will be linked
      }

      // Step 5: Check if profile exists, if not, user needs to complete profile
      print('🔵 Checking if profile exists...');
      bool profileExists = false;
      try {
        // Wait a bit for the profile update to complete
        await Future.delayed(const Duration(milliseconds: 500));
        final profileCheck = await _supabase
            .from('user_profiles')
            .select('id')
            .eq('id', response.user!.id)
            .maybeSingle();

        profileExists = profileCheck != null;

        if (profileExists) {
          await _loadUserProfile();
          print('✅ User profile loaded: ${currentUser.value?.fullName}');
        } else {
          print('⚠️ Profile not found - user needs to complete profile');
        }
      } catch (profileLoadError) {
        print('⚠️ Profile check warning (non-fatal): $profileLoadError');
        profileExists = false;
      }

      // Store whether profile needs completion
      _needsProfileCompletion = !profileExists;

      // Step 6: Ensure session is properly set before returning
      // This is critical for profile completion screen
      if (_needsProfileCompletion) {
        print('🔵 Ensuring session is set for profile completion...');
        try {
          // Check if we have a current user
          var authenticatedUser = _supabase.auth.currentUser;
          if (authenticatedUser == null) {
            // Try to refresh session
            final session = response.session;
            if (session != null && session.refreshToken != null) {
              try {
                await _supabase.auth.setSession(session.refreshToken!);
                authenticatedUser = _supabase.auth.currentUser;
                print('✅ Session set for profile completion');
              } catch (e) {
                print('⚠️ Could not set session for profile completion: $e');
                // Try refresh
                try {
                  await _supabase.auth.refreshSession();
                  authenticatedUser = _supabase.auth.currentUser;
                  print('✅ Session refreshed for profile completion');
                } catch (refreshError) {
                  print('⚠️ Could not refresh session: $refreshError');
                }
              }
            }
          }

          // If still no user, we have a problem
          if (authenticatedUser == null) {
            print(
              '⚠️ Warning: No authenticated user after signup - profile completion may fail',
            );
            print('⚠️ User will need to sign in to complete profile');
          }
        } catch (e) {
          print('⚠️ Session verification warning (non-fatal): $e');
        }
      }

      // Step 7: Save session
      print('🔵 Saving session...');
      try {
        await SupabaseService.saveUserSession(response.user!.id, email);
        print('✅ Session saved');
      } catch (sessionError) {
        print('⚠️ Session save warning (non-fatal): $sessionError');
      }

      return true;
    } catch (e) {
      ErrorHandler.logError(e, context: 'Sign up');
      errorMessage.value = ErrorHandler.getUserFriendlyMessage(e);
      return false;
    } finally {
      print('🔵 Setting isLoading to false');
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear Remember Me tokens
      try {
        await StorageService.clearUserSession();
      } catch (e) {
        print('⚠️ Could not clear storage (non-fatal): $e');
      }

      // Sign out from Supabase
      await _supabase.auth.signOut();

      // Clear user session
      try {
        await SupabaseService.clearUserSession();
      } catch (e) {
        print('⚠️ Could not clear user session (non-fatal): $e');
      }

      currentUser.value = null;
      print('✅ Signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      // Still clear local state even if sign out fails
      currentUser.value = null;
    }
  }

  // Load user profile from database
  Future<void> reloadUserProfile() async {
    await _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        currentUser.value = UserModel.fromJson(response);
        print(
          '✅ Profile loaded: ${currentUser.value?.fullName} (${currentUser.value?.email})',
        );
      } else {
        print('⚠️ No profile found for user ID: $userId');
        // Try to find by email as fallback
        final email = _supabase.auth.currentUser?.email;
        if (email != null) {
          print('🔵 Trying to find profile by email: $email');
          final emailResponse = await _supabase
              .from('user_profiles')
              .select()
              .eq('email', email)
              .maybeSingle();
          if (emailResponse != null) {
            currentUser.value = UserModel.fromJson(emailResponse);
            print('✅ Profile loaded by email: ${currentUser.value?.fullName}');
          }
        }
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
    }
  }

  // Get current user
  UserModel? get user => currentUser.value;

  // Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Sign up via REST API to bypass shared_preferences issue
  Future<AuthResponse> _signUpViaRestApi(String email, String password) async {
    const supabaseUrl = 'https://uvbixnbbbalqqhhzxjml.supabase.co';
    const supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2Yml4bmJiYmFscXFoaHp4am1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1MDEwNzMsImV4cCI6MjA4MjA3NzA3M30.W62r_n4pCM1s5FCrVnd-ywu6845C1FTm53ltXZ9DYSs';

    final url = Uri.parse('$supabaseUrl/auth/v1/signup');

    print('🔵 Making REST API call to: $url');

    final response = await http
        .post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
      },
      body: jsonEncode({'email': email, 'password': password}),
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('REST API sign up timed out');
      },
    );

    print('🔵 REST API response status: ${response.statusCode}');
    print('🔵 REST API response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('🔵 Parsed response data keys: ${data.keys.toList()}');

      // Check if we have a user in the response
      if (data['id'] != null || data['user'] != null) {
        // Supabase returns user data directly in the response, not nested
        final userData = data['user'] ?? data;
        final user = User.fromJson(userData);

        print('✅ User created: ${user?.id ?? "unknown"}');
        print('🔵 Email: ${user?.email ?? "unknown"}');

        if (user == null) {
          throw Exception('Failed to parse user from response');
        }

        // Check if we have a session (access_token in response)
        Session? session;
        if (data['access_token'] != null) {
          // Build session object from response
          final sessionData = {
            'access_token': data['access_token'],
            'token_type': data['token_type'] ?? 'bearer',
            'expires_in': data['expires_in'],
            'expires_at': data['expires_at'],
            'refresh_token': data['refresh_token'],
            'user': userData,
          };
          session = Session.fromJson(sessionData);
          print('✅ Session found in response (parsed from access_token)');

          // Try to set the session, but don't fail if it hangs
          final accessToken = session?.accessToken;
          final refreshToken = session?.refreshToken;
          if (accessToken != null && refreshToken != null) {
            try {
              await _supabase.auth
                  .setSession(refreshToken)
                  .timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  print('⚠️ setSession timed out, but user is created');
                  throw TimeoutException('setSession timed out');
                },
              );
              print('✅ Session set successfully');
            } catch (e) {
              print('⚠️ Could not set session (non-fatal): $e');
              // Try alternative: set session using refresh token directly
              try {
                await _supabase.auth.refreshSession();
                print('✅ Session refreshed successfully');
              } catch (refreshError) {
                print('⚠️ Could not refresh session: $refreshError');
                // Continue anyway - user is created, session will be set on next auth call
              }
            }
          }
        } else if (data['session'] != null) {
          // Fallback: session nested in response
          session = Session.fromJson(data['session']);
          print('✅ Session found in response (nested)');

          final accessToken = session?.accessToken;
          if (accessToken != null) {
            try {
              await _supabase.auth
                  .setSession(accessToken)
                  .timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  print('⚠️ setSession timed out, but user is created');
                  throw TimeoutException('setSession timed out');
                },
              );
              print('✅ Session set successfully');
            } catch (e) {
              print('⚠️ Could not set session (non-fatal): $e');
            }
          }
        } else {
          print(
            '⚠️ No session in response (email confirmation may be required)',
          );
          print(
            '⚠️ User will need to confirm email or sign in after confirmation',
          );
        }

        return AuthResponse(user: user, session: session);
      } else {
        print('❌ No user data in response');
        throw Exception('Invalid response from server: No user data');
      }
    } else {
      final errorData = jsonDecode(response.body);
      final errorMsg =
          errorData['msg'] ?? errorData['message'] ?? 'Sign up failed';
      print('❌ REST API error: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔵 Resetting password for: $email');

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'nilefind://reset-password', // Deep link for password reset
      );

      print('✅ Password reset email sent');
      errorMessage.value = '';
      return true;
    } catch (e) {
      print('❌ Password reset error: $e');
      final errorStr = e.toString();

      if (errorStr.contains('User not found')) {
        errorMessage.value = 'No account found with this email address.';
      } else {
        errorMessage.value = 'Failed to send reset email. Please try again.';
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
