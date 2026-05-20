
class ErrorHandler {
  
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    final errorString = error.toString().toLowerCase();

    
    if (errorString.contains('connection reset') ||
        errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable')) {
      if (errorString.contains('permission denied')) {
        return 'Network permission denied. Please check app permissions.';
      }
      return 'Connection error. Please check your internet connection and try again.';
    }

    
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    
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

    
    if (errorString.contains('postgrestexception') ||
        errorString.contains('could not find')) {
      if (errorString.contains('new row violates row-level security') ||
          errorString.contains('permission denied')) {
        return 'Permission denied. You may need to sign in again.';
      }
      return 'Unable to fetch data. Please try again later.';
    }

    
    if (errorString.contains('storageexception') ||
        errorString.contains('unauthorized') ||
        errorString.contains('403')) {
      return 'Unable to upload file. Please check your permissions and try again.';
    }

    
    if (errorString.contains('exception') || errorString.contains('error')) {
      return 'Something went wrong. Please try again.';
    }

    
    return 'An unexpected error occurred. Please try again.';
  }

  
  static void logError(dynamic error, {String? context}) {
    
    
    
    if (context != null) {
      
    }
  }
}
