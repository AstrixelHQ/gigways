import 'package:flutter/material.dart';

class PolicyModel {
  final String title;
  final String description;
  final IconData icon;
  final DateTime lastUpdated;
  final List<PolicySection> content;

  PolicyModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.lastUpdated,
    required this.content,
  });
}

class PolicySection {
  final String title;
  final String content;

  PolicySection({
    required this.title,
    required this.content,
  });
}
