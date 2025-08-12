enum ErrorType {
  network,
  timeout,
  apiLimit,
  invalidApiKey,
  notFound,
  server,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final String userMessage;
  final bool canRetry;

  const AppError({
    required this.type,
    required this.message,
    required this.userMessage,
    this.canRetry = true,
  });

  factory AppError.network() {
    return const AppError(
      type: ErrorType.network,
      message: 'No internet connection',
      userMessage: 'Check your internet connection and try again',
      canRetry: true,
    );
  }

  factory AppError.timeout() {
    return const AppError(
      type: ErrorType.timeout,
      message: 'Request timeout',
      userMessage: 'The request is taking too long. Please try again',
      canRetry: true,
    );
  }

  factory AppError.apiLimit() {
    return const AppError(
      type: ErrorType.apiLimit,
      message: 'API limit exceeded',
      userMessage: 'Too many requests. Please wait a moment and try again',
      canRetry: true,
    );
  }

  factory AppError.invalidApiKey() {
    return const AppError(
      type: ErrorType.invalidApiKey,
      message: 'Invalid API key',
      userMessage: 'Service temporarily unavailable. Please try again later',
      canRetry: false,
    );
  }

  factory AppError.notFound() {
    return const AppError(
      type: ErrorType.notFound,
      message: 'Resource not found',
      userMessage: 'No results found for your search',
      canRetry: false,
    );
  }

  factory AppError.server() {
    return const AppError(
      type: ErrorType.server,
      message: 'Server error',
      userMessage: 'Server is experiencing issues. Please try again later',
      canRetry: true,
    );
  }

  factory AppError.unknown(String message) {
    return AppError(
      type: ErrorType.unknown,
      message: message,
      userMessage: 'Something went wrong. Please try again',
      canRetry: true,
    );
  }
}
