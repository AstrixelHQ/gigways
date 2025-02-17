import 'package:flutter/material.dart';
import 'package:gigways/features/setting/models/faq_model.dart';
import 'package:gigways/features/setting/models/policy_model.dart';

abstract class AppConstant {
  const AppConstant._();

  static const String appName = 'Gigways Hero';
  static const String appVersion = '1.0.0';

  static List<FaqModel> faq = [
    FaqModel(
      question: 'How do I create an account?',
      answer:
          'To create an account, click on the "Sign Up" button on the home screen. Fill in your details including name, email, and password. Verify your email address through the link sent to your inbox.',
    ),
    FaqModel(
      question: 'What payment methods are accepted?',
      answer:
          'We accept various payment methods including credit/debit cards (Visa, MasterCard, American Express), PayPal, and bank transfers. All payments are processed securely through our payment gateway.',
    ),
    FaqModel(
      question: 'How can I reset my password?',
      answer:
          'Click on "Forgot Password" on the login screen. Enter your registered email address and follow the instructions sent to your email to create a new password.',
    ),
    FaqModel(
      question: 'How do I contact customer support?',
      answer:
          'You can reach our customer support team through the "Help" section in the app, or email us at support@gigways.com. Our team typically responds within 24 hours.',
    ),
    FaqModel(
      question: 'Is my personal information secure?',
      answer:
          'Yes, we take data security seriously. All personal information is encrypted and stored securely. We never share your data with third parties without your consent.',
    ),
  ];

  static final List<PolicyModel> policies = [
    PolicyModel(
      title: 'Terms of Service',
      description: 'Our terms of service and user agreement',
      icon: Icons.description_outlined,
      lastUpdated: DateTime(2024, 1, 15),
      content: [
        PolicySection(
          title: 'Introduction',
          content:
              'These Terms of Service govern your use of our application and services. By accessing or using our services, you agree to these terms.',
        ),
        PolicySection(
          title: 'Account Registration',
          content:
              'You must register for an account to access certain features. You are responsible for maintaining the security of your account credentials.',
        ),
        PolicySection(
          title: 'User Responsibilities',
          content:
              'Users must comply with all applicable laws and regulations. Any misuse of the service may result in account termination.',
        ),
      ],
    ),
    PolicyModel(
      title: 'Privacy Policy',
      description: 'How we collect and handle your data',
      icon: Icons.privacy_tip_outlined,
      lastUpdated: DateTime(2024, 2, 1),
      content: [
        PolicySection(
          title: 'Data Collection',
          content:
              'We collect information you provide directly to us, including but not limited to your name, email address, and usage data.',
        ),
        PolicySection(
          title: 'Data Usage',
          content:
              'Your data is used to provide and improve our services, communicate with you, and ensure platform security.',
        ),
        PolicySection(
          title: 'Data Protection',
          content:
              'We implement appropriate security measures to protect your personal information from unauthorized access or disclosure.',
        ),
      ],
    ),
    PolicyModel(
      title: 'Cookie Policy',
      description: 'Information about our use of cookies',
      icon: Icons.cookie_outlined,
      lastUpdated: DateTime(2024, 1, 30),
      content: [
        PolicySection(
          title: 'What are Cookies',
          content:
              'Cookies are small text files stored on your device that help us provide and improve our services.',
        ),
        PolicySection(
          title: 'How We Use Cookies',
          content:
              'We use cookies to remember your preferences, understand how you use our service, and improve your experience.',
        ),
      ],
    ),
    PolicyModel(
      title: 'Community Guidelines',
      description: 'Rules and standards for our community',
      icon: Icons.people_outline,
      lastUpdated: DateTime(2024, 1, 20),
      content: [
        PolicySection(
          title: 'General Conduct',
          content:
              'Users must treat each other with respect and refrain from harmful or discriminatory behavior.',
        ),
        PolicySection(
          title: 'Content Standards',
          content:
              'All content must comply with our guidelines. Prohibited content will be removed and may result in account suspension.',
        ),
      ],
    ),
  ];
}
