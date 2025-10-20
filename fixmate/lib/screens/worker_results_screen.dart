// lib/screens/worker_results_screen.dart
// FIXED VERSION - Creates worker in database if not exists before creating quote

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ml_service.dart';
import '../services/quote_service.dart';
import '../services/worker_storage_service.dart';
import '../models/worker_model.dart';
import 'worker_detail_screen.dart';

class WorkerResultsScreen extends StatefulWidget {
  final List<MLWorker> workers;
  final AIAnalysis aiAnalysis;
  final String problemDescription;
  final List<String> problemImageUrls;

  const WorkerResultsScreen({
    Key? key,
    required this.workers,
    required this.aiAnalysis,
    required this.problemDescription,
    this.problemImageUrls = const [],
  }) : super(key: key);

  @override
  State<WorkerResultsScreen> createState() => _WorkerResultsScreenState();
}

class _WorkerResultsScreenState extends State<WorkerResultsScreen> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Recommended Workers', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Compact AI Analysis Summary
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smart_toy, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.verified_user,
                        color: Colors.white.withOpacity(0.8), size: 18),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  widget.problemDescription,
                  style: TextStyle(fontSize: 13, color: Colors.white),
                  maxLines: _isDescriptionExpanded ? 100 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.problemDescription.length > 80)
                  TextButton(
                    onPressed: () => setState(
                        () => _isDescriptionExpanded = !_isDescriptionExpanded),
                    child: Text(
                      _isDescriptionExpanded ? 'Show Less' : 'Show More',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildCompactChip(
                      Icons.build,
                      widget.aiAnalysis.servicePredictions.first.serviceType
                          .replaceAll('_', ' ')
                          .split(' ')
                          .map((word) =>
                              word[0].toUpperCase() + word.substring(1))
                          .join(' '),
                    ),
                    _buildCompactChip(
                      Icons.location_on,
                      widget.aiAnalysis.userInputLocation,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Workers List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: widget.workers.length,
              itemBuilder: (context, index) {
                final worker = widget.workers[index];
                return _buildWorkerCard(worker);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(MLWorker worker) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewWorkerDetails(worker),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.person, color: Colors.blue, size: 30),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.workerName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          worker.serviceType.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.smart_toy,
                            size: 14, color: Colors.green.shade700),
                        SizedBox(width: 4),
                        Text(
                          '${(worker.aiConfidence * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildStatItem(Icons.star, '${worker.rating}', Colors.amber),
                  _buildStatItem(
                      Icons.work, '${worker.experienceYears} yrs', Colors.blue),
                  _buildStatItem(Icons.location_on,
                      '${worker.distanceKm.toStringAsFixed(1)} km', Colors.red),
                ],
              ),
              Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LKR ${worker.dailyWageLkr}/day',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _callWorker(worker.phoneNumber),
                        icon: Icon(Icons.phone, color: Colors.green),
                        tooltip: 'Call Worker',
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _viewWorkerDetails(worker),
                        icon: Icon(Icons.info_outline, color: Colors.blue),
                        tooltip: 'View Details',
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _createQuote(worker),
                  icon:
                      Icon(Icons.request_quote, color: Colors.white, size: 20),
                  label: Text(
                    'Create Quote',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _viewWorkerDetails(MLWorker worker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerDetailScreen(
          worker: worker,
          problemDescription: widget.problemDescription,
          problemImageUrls: widget.problemImageUrls,
        ),
      ),
    );
  }

  void _callWorker(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch phone dialer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // FIXED: Create quote with proper worker creation if needed
  Future<void> _createQuote(MLWorker worker) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Quote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to request a quote from:'),
            SizedBox(height: 16),
            Text('Worker: ${worker.workerName}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Service: ${worker.serviceType.replaceAll('_', ' ')}'),
            Text('Rate: LKR ${worker.dailyWageLkr}/day'),
            SizedBox(height: 8),
            Text('Location: ${worker.city}',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm Quote'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _sendQuoteRequest(worker);
    }
  }

  // FIXED: Send quote request with proper worker creation
  Future<void> _sendQuoteRequest(MLWorker worker) async {
    try {
      print('\n========== QUOTE CREATION FROM ML WORKER START ==========');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(width: 16),
              Text('Creating Quote...'),
            ],
          ),
        ),
      );

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) throw Exception('Customer profile not found');

      Map<String, dynamic> customerData =
          customerDoc.data() as Map<String, dynamic>;

      String customerId = customerData['customer_id'] ?? user.uid;
      String customerName = customerData['customer_name'] ??
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim();
      String customerPhone = customerData['phone_number'] ?? '';
      String customerEmail = customerData['email'] ?? user.email ?? '';

      // CRITICAL FIX: Check if worker exists, create if needed
      print('🔍 Checking if worker exists in database...');
      print('   Email: ${worker.email}');
      print('   Phone: ${worker.phoneNumber}');

      String? existingWorkerId = await WorkerStorageService.getExistingWorkerId(
        email: worker.email,
        phoneNumber: worker.phoneNumber,
      );

      String workerId;

      if (existingWorkerId != null) {
        // Worker already exists
        workerId = existingWorkerId;
        print('✅ Worker already exists with ID: $workerId');
      } else {
        // Worker doesn't exist, create new worker
        print('📝 Worker not found, creating new worker account...');

        // Show creating worker message
        Navigator.pop(context); // Close previous dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.orange),
                SizedBox(width: 16),
                Text('Creating worker profile...'),
              ],
            ),
          ),
        );

        // Create worker using WorkerStorageService
        workerId = await WorkerStorageService.storeWorkerFromML(
          mlWorker: worker,
        );

        print('✅ New worker created with ID: $workerId');

        // Close creating worker dialog and show quote creation dialog
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(width: 16),
                Text('Creating Quote...'),
              ],
            ),
          ),
        );
      }

      // Verify workerId format
      if (!workerId.startsWith('HM_')) {
        throw Exception(
            'Invalid worker_id format: $workerId (expected HM_XXXX format)');
      }

      print('✅ Using worker_id: $workerId (HM_XXXX format)');

      // Get service details from AI analysis
      String serviceType =
          widget.aiAnalysis.servicePredictions.first.serviceType;
      String subService = 'General Service';
      String issueType = 'General Issue';

      print('📋 Creating quote...');
      print('   Customer: $customerName ($customerId)');
      print('   Worker: ${worker.workerName} ($workerId)');
      print('   Service: $serviceType');

      // Create quote using QuoteService
      String quoteId = await QuoteService.createQuote(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        workerId: workerId,
        workerName: worker.workerName,
        workerPhone: worker.phoneNumber,
        serviceType: serviceType,
        subService: subService,
        issueType: issueType,
        problemDescription: widget.problemDescription,
        problemImageUrls: widget.problemImageUrls,
        location: widget.aiAnalysis.userInputLocation,
        address: widget.aiAnalysis.userInputLocation,
        urgency: 'normal',
        budgetRange: 'LKR ${worker.dailyWageLkr}',
        scheduledDate: DateTime.now().add(Duration(days: 1)),
        scheduledTime: '09:00 AM',
      );

      print('✅ Quote created successfully!');
      print('   Quote ID: $quoteId');
      print('========== QUOTE CREATION FROM ML WORKER END ==========\n');

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Quote Sent Successfully!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your quote request has been sent to ${worker.workerName}.'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Next Steps:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. The worker will review your request',
                      style:
                          TextStyle(fontSize: 13, color: Colors.blue.shade700),
                    ),
                    Text(
                      '2. You\'ll receive a quote with pricing',
                      style:
                          TextStyle(fontSize: 13, color: Colors.blue.shade700),
                    ),
                    Text(
                      '3. You can accept or decline the quote',
                      style:
                          TextStyle(fontSize: 13, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Error creating quote: $e');
      print('========== QUOTE CREATION FROM ML WORKER END ==========\n');

      // Close any open dialogs
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text('Error'),
            ],
          ),
          content: Text('Failed to create quote: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
