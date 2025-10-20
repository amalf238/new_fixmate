// lib/screens/service_request_flow.dart
// ✅ COMPLETE FIXED VERSION - All errors resolved
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enhanced_worker_selection_screen.dart';
import '../services/storage_service.dart';
import 'dart:typed_data';

class ServiceRequestFlow extends StatefulWidget {
  final String serviceType;
  final String subService;
  final String serviceName;

  const ServiceRequestFlow({
    Key? key,
    required this.serviceType,
    required this.subService,
    required this.serviceName,
  }) : super(key: key);

  @override
  _ServiceRequestFlowState createState() => _ServiceRequestFlowState();
}

class _ServiceRequestFlowState extends State<ServiceRequestFlow> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  bool _isLoading = false;
  String _currentAddress = '';

  // Form data
  String? _selectedIssueType;
  String? _selectedLocation;
  String _problemDescription = '';
  String? _waterSupplyStatus;
  String _urgency = 'Same day';
  String _budgetRange = 'LKR 10000-LKR 15000';

  // ✅ FIX 1: Changed from List<File> to List<XFile>
  List<XFile> _selectedImages = [];

  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.95),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              '${widget.serviceName} Services',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / _totalSteps,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getStepTitle(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Step ${_currentStep + 1} of $_totalSteps',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildCurrentStep(),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Issue Details';
      case 1:
        return 'Location & Details';
      case 2:
        return 'Additional Information';
      case 3:
        return 'Review & Confirm';
      default:
        return 'Service Request';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildIssueDetailsStep();
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildAdditionalInfoStep();
      case 3:
        return _buildReviewStep();
      default:
        return Container();
    }
  }

  Widget _buildIssueDetailsStep() {
    List<Map<String, String>> issueTypes = _getIssueTypes();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of ${widget.serviceName.toLowerCase()} issue are you experiencing?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),
          ...issueTypes.map((issue) => _buildRadioOption(
                issue['label']!,
                issue['value']!,
                _selectedIssueType,
                (value) => setState(() => _selectedIssueType = value),
              )),
          SizedBox(height: 16),
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    List<Map<String, String>> locations = _getLocationOptions();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where is the ${widget.serviceName.toLowerCase()} service needed?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),
          ...locations.map((location) => _buildRadioOption(
                location['label']!,
                location['value']!,
                _selectedLocation,
                (value) => setState(() => _selectedLocation = value),
              )),
          SizedBox(height: 20),
          Text(
            'Problem Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail...',
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() => _problemDescription = value),
            ),
          ),
          if (widget.serviceType == 'plumbing') ...[
            SizedBox(height: 20),
            Text(
              'Water Supply Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            _buildDropdown(
              value: _waterSupplyStatus,
              hint: 'Select water supply status',
              items: ['Normal', 'Low pressure', 'No water', 'Intermittent'],
              onChanged: (value) => setState(() => _waterSupplyStatus = value),
            ),
          ],
          SizedBox(height: 16),
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Urgency',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          _buildDropdown(
            value: _urgency,
            hint: 'Select urgency',
            items: [
              'Emergency (ASAP)',
              'Same day',
              'Within 2-3 days',
              'Within a week',
              'Flexible'
            ],
            onChanged: (value) =>
                setState(() => _urgency = value ?? 'Same day'),
          ),
          SizedBox(height: 20),
          Text(
            'Budget Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          _buildDropdown(
            value: _budgetRange,
            hint: 'Select budget range',
            items: [
              'LKR 5000-LKR 10000',
              'LKR 10000-LKR 15000',
              'LKR 15000-LKR 25000',
              'LKR 25000-LKR 50000',
              'LKR 50000+',
            ],
            onChanged: (value) =>
                setState(() => _budgetRange = value ?? 'LKR 10000-LKR 15000'),
          ),
          SizedBox(height: 24),
          Text(
            'Upload photos (optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Photos help service providers understand your needs better',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          _buildImageUploadSection(),
          SizedBox(height: 16),
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildSummaryContainer(),
          SizedBox(height: 24),
          _buildInfoBox(),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryContainer() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow('Issue Type:',
              _selectedIssueType?.replaceAll('_', ' ') ?? 'Not specified'),
          _buildSummaryRow('Location:',
              _selectedLocation?.replaceAll('_', ' ') ?? 'Not specified'),
          _buildSummaryRow(
            'Description:',
            _problemDescription.isNotEmpty
                ? _problemDescription
                : 'No description provided',
          ),
          if (widget.serviceType == 'plumbing' && _waterSupplyStatus != null)
            _buildSummaryRow('Water Supply Status:', _waterSupplyStatus!),
          _buildSummaryRow('Urgency:', _urgency),
          _buildSummaryRow('Budget Range:', _budgetRange),
          if (_selectedImages.isNotEmpty)
            _buildSummaryRow(
                'Photos:', '${_selectedImages.length} image(s) attached'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Back & Edit'),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _goToNextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep < _totalSteps - 1
                    ? Colors.blue
                    : Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep < _totalSteps - 1
                    ? 'Next'
                    : 'Confirm & Get Quotes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _proceedToWorkerSelection();
    }
  }

  // ✅ FIX 2: Updated method to use correct StorageService method
  Future<void> _proceedToWorkerSelection() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> uploadedPhotoUrls = [];

      if (_selectedImages.isNotEmpty) {
        print('📤 Uploading ${_selectedImages.length} photos...');

        for (int i = 0; i < _selectedImages.length; i++) {
          XFile imageFile = _selectedImages[i]; // ✅ Now it's XFile
          print('   Uploading photo ${i + 1}/${_selectedImages.length}...');

          // ✅ FIX: Use correct method name - uploadIssuePhoto (not uploadImage)
          String photoUrl = await StorageService.uploadIssuePhoto(
            imageFile: imageFile, // ✅ Pass XFile directly
          );

          uploadedPhotoUrls.add(photoUrl);
          print('   ✅ Photo ${i + 1} uploaded: $photoUrl');
        }

        print('✅ All ${uploadedPhotoUrls.length} photos uploaded successfully');
      }

      _problemDescription = _descriptionController.text.trim();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedWorkerSelectionScreen(
            serviceType: widget.serviceType,
            subService: widget.subService,
            issueType: _selectedIssueType ?? 'other',
            problemDescription: _problemDescription,
            problemImageUrls: uploadedPhotoUrls,
            location: _selectedLocation ?? 'other',
            address: _currentAddress,
            urgency: _urgency,
            budgetRange: _budgetRange,
            scheduledDate: DateTime.now().add(Duration(days: 1)),
            scheduledTime: _urgency == 'Same day'
                ? 'As soon as possible'
                : '09:00 AM - 12:00 PM',
          ),
        ),
      );
    } catch (e) {
      print('❌ Error in _proceedToWorkerSelection: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Failed to proceed: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _proceedToWorkerSelection(),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedIssueType != null;
      case 1:
        return _selectedLocation != null && _problemDescription.isNotEmpty;
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  // ✅ FIX 3: Updated to store XFile directly
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImages.add(image); // ✅ Store XFile directly
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildRadioOption(String label, String value, String? selectedValue,
      Function(String) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedValue,
        onChanged: (value) => onChanged(value!),
        title: Text(label),
        activeColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _buildImageUploadCard(
            icon: Icons.photo_library,
            label: 'Choose from Gallery',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(height: 16),
          _buildSelectedImagesGrid(),
        ],
      ],
    );
  }

  Widget _buildImageUploadCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIX 4: Updated to display XFile images properly
  Widget _buildSelectedImagesGrid() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FutureBuilder<Uint8List>(
                      future: _selectedImages[index].readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        }
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service providers will review your request and send quotes.',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'You\'ll be notified when quotes are available.',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getIssueTypes() {
    switch (widget.serviceType) {
      case 'plumbing':
        return [
          {'label': 'Leak or drip', 'value': 'leak_or_drip'},
          {'label': 'Blocked drain', 'value': 'blocked_drain'},
          {'label': 'Installation needed', 'value': 'installation_needed'},
          {'label': 'Repair needed', 'value': 'repair_needed'},
          {'label': 'Emergency issue', 'value': 'emergency_issue'},
          {'label': 'Other', 'value': 'other'},
        ];
      case 'electrical':
        return [
          {'label': 'Power outage', 'value': 'power_outage'},
          {'label': 'Faulty wiring', 'value': 'faulty_wiring'},
          {'label': 'Installation needed', 'value': 'installation_needed'},
          {'label': 'Repair needed', 'value': 'repair_needed'},
          {'label': 'Emergency issue', 'value': 'emergency_issue'},
          {'label': 'Other', 'value': 'other'},
        ];
      default:
        return [
          {'label': 'Installation needed', 'value': 'installation_needed'},
          {'label': 'Repair needed', 'value': 'repair_needed'},
          {'label': 'Maintenance required', 'value': 'maintenance_required'},
          {'label': 'Emergency issue', 'value': 'emergency_issue'},
          {'label': 'Other', 'value': 'other'},
        ];
    }
  }

  List<Map<String, String>> _getLocationOptions() {
    return [
      {'label': 'Kitchen', 'value': 'kitchen'},
      {'label': 'Bathroom', 'value': 'bathroom'},
      {'label': 'Living room', 'value': 'living_room'},
      {'label': 'Bedroom', 'value': 'bedroom'},
      {'label': 'Garage', 'value': 'garage'},
      {'label': 'Basement', 'value': 'basement'},
      {'label': 'Outdoor area', 'value': 'outdoor_area'},
      {'label': 'Other', 'value': 'other'},
    ];
  }
}
