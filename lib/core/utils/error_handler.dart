/// Utility class for handling and displaying user-friendly error messages
class ErrorHandler {
  /// Converts technical error messages to user-friendly messages
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    final errorString = error.toString().toLowerCase();

    // Connection errors
    if (errorString.contains('connection reset') ||
        errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable')) {
      return 'Connection timeout. Please check your internet connection and try again.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Authentication errors
    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid password')) {
      return 'Invalid password. Please try again.';
    }

    if (errorString.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }

    if (errorString.contains('user not found') ||
        errorString.contains('user not authenticated')) {
      return 'User not authenticated. Please sign in again.';
    }

    // Database errors
    if (errorString.contains('postgrestexception') ||
        errorString.contains('could not find')) {
      if (errorString.contains('new row violates row-level security') ||
          errorString.contains('permission denied')) {
        return 'Permission denied. You may need to sign in again.';
      }
      return 'Unable to fetch data. Please try again later.';
    }

    // Storage errors
    if (errorString.contains('storageexception') ||
        errorString.contains('unauthorized') ||
        errorString.contains('403')) {
      return 'Unable to upload file. Please check your permissions and try again.';
    }

    // Generic errors
    if (errorString.contains('exception') || errorString.contains('error')) {
      return 'Something went wrong. Please try again.';
    }

    // Default message
    return 'An unexpected error occurred. Please try again.';
  }

  /// Logs error without exposing technical details to users
  static void logError(dynamic error, {String? context}) {
    // In production, you might want to send this to a logging service
    // For now, we'll just suppress console logs as requested
    // Only log in debug mode if needed
    if (context != null) {
      // Silent logging - no console output
    }
  }
}
