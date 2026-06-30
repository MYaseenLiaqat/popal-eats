import 'package:flutter/material.dart';

/// Admin portal navigation destinations.
enum AdminSection {
  dashboard(Icons.dashboard_outlined, 'Dashboard'),
  approvals(Icons.approval_outlined, 'Business Approvals'),
  restaurants(Icons.storefront_outlined, 'Restaurants'),
  homeChefs(Icons.soup_kitchen_outlined, 'Home Chefs'),
  customers(Icons.people_outline, 'Customers'),
  content(Icons.shield_outlined, 'Content Moderation'),
  orders(Icons.receipt_long_outlined, 'Orders'),
  reviews(Icons.rate_review_outlined, 'Reviews'),
  reports(Icons.summarize_outlined, 'Reports'),
  analytics(Icons.insights_outlined, 'Analytics'),
  ai(Icons.psychology_outlined, 'AI Recommendations'),
  settings(Icons.settings_outlined, 'Settings'),
  profile(Icons.person_outline, 'Profile');

  const AdminSection(this.icon, this.label);

  final IconData icon;
  final String label;
}
