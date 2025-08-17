import '../constants/strings.dart';

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
      message: AppStrings.noInternetConnectionTech,
      userMessage: AppStrings.checkInternetAndRetry,
      canRetry: true,
    );
  }

  factory AppError.timeout() {
    return const AppError(
      type: ErrorType.timeout,
      message: AppStrings.requestTimeoutTech,
      userMessage: AppStrings.requestTakingTooLong,
      canRetry: true,
    );
  }

  factory AppError.apiLimit() {
    return const AppError(
      type: ErrorType.apiLimit,
      message: AppStrings.apiLimitExceededTech,
      userMessage: AppStrings.serviceTempUnavailable,
      canRetry: true,
    );
  }

  factory AppError.invalidApiKey() {
    return const AppError(
      type: ErrorType.invalidApiKey,
      message: AppStrings.apiLimitExceededTech,
      userMessage: AppStrings.serviceTempUnavailable,
      canRetry: false,
    );
  }

  factory AppError.notFound() {
    return const AppError(
      type: ErrorType.notFound,
      message: AppStrings.resourceNotFoundTech,
      userMessage: AppStrings.noResultsForSearch,
      canRetry: false,
    );
  }

  factory AppError.server() {
    return const AppError(
      type: ErrorType.server,
      message: AppStrings.serverErrorTech,
      userMessage: AppStrings.serverExperiencingIssues,
      canRetry: true,
    );
  }

  factory AppError.unknown(String message) {
    return AppError(
      type: ErrorType.unknown,
      message: message,
      userMessage: AppStrings.somethingWentWrongRetry,
      canRetry: true,
    );
  }
}
