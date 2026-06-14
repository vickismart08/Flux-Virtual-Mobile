import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          """
PRIVACY POLICY

Effective Date: June 4, 2026
App Name: Flux Virtual
Contact: fluxvirtualofficial@gmail.com

Flux Virtual operates a mobile application that provides virtual phone numbers, SMS reception, calling features, and future eSIM services.

1. INFORMATION WE COLLECT
- Name
- Email address
- Login credentials (email/password or Google/Apple)
- Contacts (if permission granted)
- Device and usage data
- Payment information (handled securely via third-party providers)

2. HOW WE USE INFORMATION
We use your data to:
- Provide virtual number services
- Manage accounts
- Process payments
- Improve app performance
- Prevent fraud

3. PAYMENT PROVIDER
Payments are processed securely through Paystack. We do not store full card details.

4. THIRD-PARTY SERVICES
We use Firebase and Google/Apple authentication services.

5. DATA SHARING
We do not sell or trade user data.

6. SECURITY
We use industry-standard security measures to protect user data.

7. CONTACT
fluxvirtualofficial@gmail.com
          """,
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}