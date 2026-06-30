import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/username_check_result.dart';
import '../providers/onboarding_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/home_chef_owner_service.dart';
import '../services/restaurant_owner_service.dart';
import '../utils/app_roles.dart';
import '../utils/auth_validation.dart';
import '../utils/recommendation_copy.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = AuthService();
  Map<String, dynamic>? user;
  bool loading = false;
  bool initializing = true;
  String? error;
  String? lastLoginMessage;

  bool get isLoggedIn => ApiClient.instance.isAuthenticated;
  bool get googleSignInAvailable => GoogleAuthService.isConfigured;
  String? get userRole => AppRoles.roleOf(user);
  String? get accountStatus => AppRoles.accountStatusOf(user);

  Future<void> init() async {
    try {
      await ApiClient.instance.loadToken();
      if (isLoggedIn) {
        try {
          user = await _auth.me();
        } catch (_) {
          await _auth.logout();
        }
      }
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  /// Reload profile from the server (e.g. after admin approval).
  Future<void> refreshUser() async {
    if (!isLoggedIn) return;
    user = await _auth.me();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    loading = true;
    error = null;
    lastLoginMessage = null;
    notifyListeners();
    try {
      final tokenData = await _auth.login(email: email, password: password);
      user = await _auth.me();
      lastLoginMessage = _pendingMessage(tokenData);
      return true;
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final idToken = await GoogleAuthService.instance.signInAndGetIdToken();
      if (idToken == null) return false;
      await _auth.loginWithGoogle(idToken: idToken);
      user = await _auth.me();
      return true;
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      return false;
    } catch (e) {
      error = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required SignupRole role,
    String? firstName,
    String? lastName,
    String? username,
    required String email,
    required String phone,
    DateTime? dateOfBirth,
    required String password,
    required String confirmPassword,
    String? city,
    Map<String, dynamic>? restaurantProfile,
    Map<String, dynamic>? homeChefProfile,
    PlatformFile? restaurantCoverImage,
    PlatformFile? restaurantLogoImage,
    PlatformFile? homeChefProfileImage,
    PlatformFile? homeChefFoodLicense,
  }) async {
    loading = true;
    error = null;
    lastLoginMessage = null;
    notifyListeners();
    try {
      await _auth.register(
        role: role,
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        phone: phone,
        dateOfBirth: dateOfBirth,
        password: password,
        confirmPassword: confirmPassword,
        city: city,
        restaurantProfile: restaurantProfile,
        homeChefProfile: homeChefProfile,
      );
      final loggedIn = await login(email, password);
      if (!loggedIn) return false;
      await _uploadRegistrationImages(
        role: role,
        restaurantCoverImage: restaurantCoverImage,
        restaurantLogoImage: restaurantLogoImage,
        homeChefProfileImage: homeChefProfileImage,
        homeChefFoodLicense: homeChefFoodLicense,
      );
      return true;
    } on ApiException catch (e) {
      error = RecommendationCopy.friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _uploadRegistrationImages({
    required SignupRole role,
    PlatformFile? restaurantCoverImage,
    PlatformFile? restaurantLogoImage,
    PlatformFile? homeChefProfileImage,
    PlatformFile? homeChefFoodLicense,
  }) async {
    try {
      if (role == SignupRole.restaurant) {
        final restaurants = await RestaurantOwnerService().listMine();
        if (restaurants.isEmpty) return;
        final restaurantId = restaurants.first.id;
        final owner = RestaurantOwnerService();
        // Schema stores one hero image; prefer cover, fall back to logo.
        if (restaurantCoverImage?.bytes != null) {
          await owner.uploadRestaurantImage(
            restaurantId: restaurantId,
            bytes: restaurantCoverImage!.bytes!,
            filename: restaurantCoverImage.name,
          );
        } else if (restaurantLogoImage?.bytes != null) {
          await owner.uploadRestaurantImage(
            restaurantId: restaurantId,
            bytes: restaurantLogoImage!.bytes!,
            filename: restaurantLogoImage.name,
          );
        }
      } else if (role == SignupRole.homeChef) {
        final chef = HomeChefOwnerService();
        if (homeChefProfileImage?.bytes != null) {
          await chef.uploadProfileImage(
            bytes: homeChefProfileImage!.bytes!,
            filename: homeChefProfileImage.name,
          );
        }
        if (homeChefFoodLicense?.bytes != null) {
          await chef.uploadFoodLicense(
            bytes: homeChefFoodLicense!.bytes!,
            filename: homeChefFoodLicense.name,
          );
        }
      }
    } catch (_) {
      // Registration succeeded; image upload can be retried from profile settings.
    }
  }

  String? _pendingMessage(Map<String, dynamic> tokenData) {
    final status = tokenData['account_status']?.toString().toLowerCase();
    if (status != 'pending') return null;
    final role = tokenData['role']?.toString().toLowerCase();
    if (role == AppRoles.restaurant || role == AppRoles.restaurantOwner) {
      return 'Your restaurant account is pending admin approval.';
    }
    if (role == AppRoles.homeChef) {
      return 'Your home chef account is pending admin approval.';
    }
    return null;
  }

  Future<UsernameCheckResult> checkUsernameAvailable(String username) {
    return _auth.checkUsernameAvailable(username);
  }

  Future<void> logout() async {
    await GoogleAuthService.instance.signOut();
    await _auth.logout();
    await OnboardingProvider.clearCache();
    user = null;
    notifyListeners();
  }
}
