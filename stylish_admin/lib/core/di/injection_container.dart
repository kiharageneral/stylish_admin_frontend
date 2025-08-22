import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylish_admin/core/auth/token_manager.dart';
import 'package:stylish_admin/core/network/api_client.dart';
import 'package:stylish_admin/core/network/network_info.dart';
import 'package:stylish_admin/core/routes/dashboard_router_observer.dart';
import 'package:stylish_admin/core/service/navigation_service.dart';
import 'package:stylish_admin/core/widget/dashboard_side_bar.dart';
import 'package:stylish_admin/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:stylish_admin/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:stylish_admin/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:stylish_admin/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylish_admin/features/auth/domain/usecase/auth_usecases.dart';
import 'package:stylish_admin/features/auth/presentation/bloc/auth_bloc.dart';
final sl = GetIt.instance;
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> init() async {
  // Core services that don't depend on other services
  await _initCoreServices();
  // Auth components
  await _initAuth();
 
}

Future<void> _initCoreServices() async {
  // Navigator key for global navigation
  sl.registerLazySingleton<GlobalKey<NavigatorState>>(
    () => GlobalKey<NavigatorState>(),
  );
  sl.registerLazySingleton(() => NavigationController());
  sl.registerLazySingleton(() => NavigationService());
  sl.registerLazySingleton(() => DashboardRouterObserver(sl()));
  // shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => Connectivity());

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );
  final tokenManager = TokenManager(localDataSource: sl<AuthLocalDataSource>());
  sl.registerSingleton<TokenManager>(tokenManager);

  final apiClient = ApiClient(
    dio: Dio(),
    tokenManager: tokenManager,
    onAuthenticationFailed: () {},
  );
  sl.registerSingleton(apiClient);
}

Future<void> _initAuth() async {
  // Auth bloc
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      getCurrentUser: sl<GetCurrentUserUsecase>(),
      login: sl<LoginUseCase>(),
      logout: sl<LogoutUseCase>(),
      updateProfile: sl<UpdateProfileUseCase>(),
      validateToken: sl<ValidateTokenUseCase>(),
    ),
  );

  // Register data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      apiClient: sl<ApiClient>(),
      tokenManager: sl<TokenManager>(),
    ),
  );

  // Register repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      tokenManager: sl<TokenManager>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Register use cases
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUsecase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RefreshTokensUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ValidateTokenUseCase(sl<AuthRepository>()));
}
