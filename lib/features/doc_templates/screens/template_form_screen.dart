import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';
import '../models/template_model.dart';
import '../services/template_service.dart';

class TemplateFormScreen extends StatefulWidget {
  const TemplateFormScreen({super.key});

  @override
  State<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends State<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TemplateService();

  late DocumentTemplate template;
  late bool isBlank;
  String selectedLanguage = 'en';

  bool isLoading = false;
  List<Map<String, dynamic>> formFields = [];
  Map<String, TextEditingController> fieldControllers = {};
  Map<String, SignatureController> signatureControllers = {};

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    template = args['template'] as DocumentTemplate;
    isBlank = args['isBlank'] as bool;

    if (!isBlank) {
      _loadTemplateFields();
    }
  }

  @override
  void dispose() {
    for (var controller in fieldControllers.values) {
      controller.dispose();
    }
    for (var controller in signatureControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTemplateFields() async {
    setState(() => isLoading = true);

    try {
      final response = await _service.getTemplateDetail(
        templateId: template.id,
        language: selectedLanguage,
      );

      print('Template ID ${template.id} response: $response'); // Debug log

      if (response != null) {
        // Extract all fields from sections and fields_without_section
        final List<Map<String, dynamic>> allFields = [];

        // Process fields within sections
        if (response['sections'] != null) {
          final sections =
              List<Map<String, dynamic>>.from(response['sections']);
          print('Found ${sections.length} sections'); // Debug log

          for (var section in sections) {
            if (section['fields'] != null) {
              final sectionFields =
                  List<Map<String, dynamic>>.from(section['fields']);
              print(
                  'Section "${section['name']}" has ${sectionFields.length} fields'); // Debug log
              // Add section info to each field
              for (var field in sectionFields) {
                field['section'] = section['name'];
                field['section_sw'] = section['name_sw'];
                allFields.add(field);
              }
            }
          }
        }

        // Process fields without section
        if (response['fields_without_section'] != null) {
          final fieldsWithoutSection = List<Map<String, dynamic>>.from(
              response['fields_without_section']);
          print(
              'Found ${fieldsWithoutSection.length} fields without section'); // Debug log

          for (var field in fieldsWithoutSection) {
            // Add a default section for fields without section
            field['section'] = 'General Information';
            field['section_sw'] = 'Taarifa za Jumla';
            allFields.add(field);
          }
        }

        print('Total fields loaded: ${allFields.length}'); // Debug log

        // Sort fields by order
        allFields.sort((a, b) {
          final orderA = a['order'] as int? ?? 0;
          final orderB = b['order'] as int? ?? 0;
          return orderA.compareTo(orderB);
        });

        setState(() {
          formFields = allFields;
          // Initialize controllers for each field
          for (var field in formFields) {
            final fieldName = field['field_name'] as String;
            final fieldType = field['field_type'] as String? ?? 'text';
            
            fieldControllers[fieldName] = TextEditingController();
            
            if (fieldType == 'signature') {
              signatureControllers[fieldName] = SignatureController(
                penStrokeWidth: 3,
                penColor: Colors.black,
                exportBackgroundColor: Colors.transparent,
              );
            }
          }
        });

        // If no fields were found, show a message
        if (allFields.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'No form fields available for this template. Template ID: ${template.id}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        print('Response is null or has no sections'); // Debug log
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Template has no form fields configured. Please contact support.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading template fields: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load form fields: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _generateDocument() async {
    if (!isBlank &&
        _formKey.currentState != null &&
        !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final formData = <String, dynamic>{};

      if (!isBlank) {
            // Validate all signatures
            for (var field in formFields) {
               final fieldName = field['field_name'] as String;
               final fieldType = field['field_type'] as String? ?? 'text';
               final required = field['is_required'] as bool? ?? false;
               
               if (fieldType == 'signature' && required) {
                 final sigController = signatureControllers[fieldName];
                 if (sigController == null || sigController.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please provide your signature for ${field['label_en'] ?? fieldName}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    setState(() => isLoading = false);
                    return;
                 }
               }
            }

        for (var entry in fieldControllers.entries) {
          formData[entry.key] = entry.value.text;
        }

        // Process signatures
        for (var entry in signatureControllers.entries) {
          if (entry.value.isNotEmpty) {
            final signatureData = await entry.value.toPngBytes();
            if (signatureData != null) {
              final base64Signature = base64Encode(signatureData);
              // Sending as a data URI format which most HTML to PDF renderers support
              formData[entry.key] = 'data:image/png;base64,$base64Signature';
            }
          }
        }
      }

      // Generate document title
      String? documentTitle;
      if (!isBlank && formData.isNotEmpty) {
        final name = selectedLanguage == 'sw' ? template.nameSw : template.name;
        documentTitle = '$name - ${DateTime.now().toString().split(' ')[0]}';
      }

      final result = await _service.generatePDF(
        templateId: template.id,
        formData: formData,
        language: selectedLanguage,
        documentTitle: documentTitle,
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to my documents and replace the current screen
        Get.offNamed('/my-documents');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.name,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              template.nameSw,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          // Language toggle
          PopupMenuButton<String>(
            initialValue: selectedLanguage,
            onSelected: (value) {
              setState(() => selectedLanguage = value);
              if (!isBlank) {
                _loadTemplateFields();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'en',
                child: Text('English'),
              ),
              const PopupMenuItem(
                value: 'sw',
                child: Text('Kiswahili'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    selectedLanguage == 'en' ? 'EN' : 'SW',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isBlank
              ? _buildBlankConfirmation(theme)
              : _buildFormFields(theme),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: isLoading ? null : _generateDocument,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Generate Document',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlankConfirmation(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Generate Blank Document',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You are about to generate a blank ${template.name} template that you can fill manually.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unazo kutengeneza kiolezo tupu cha ${template.nameSw} ambacho unaweza kujaza mwenyewe.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme) {
    if (formFields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_document,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No form fields available',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    // Group fields for row layout
    final List<Widget> formWidgets = [];
    int i = 0;

    while (i < formFields.length) {
      final field = formFields[i];
      final fieldName = field['field_name'] as String;
      final fieldType = field['field_type'] as String? ?? 'text';
      final section = selectedLanguage == 'sw'
          ? (field['section_sw'] as String? ?? field['section'] as String?)
          : (field['section'] as String?);

      // Show section header if this is the first field in a new section
      final showSectionHeader =
          i == 0 || (i > 0 && formFields[i - 1]['section'] != field['section']);

      if (showSectionHeader && section != null) {
        if (i > 0) formWidgets.add(const SizedBox(height: 8));
        formWidgets.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              section,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ),
            ),
          ),
        );
        formWidgets.add(const SizedBox(height: 12));
      }

      // Check if we can group this field with the next one in a row
      final canGroupInRow = _canGroupInRow(field);
      final hasNext = i + 1 < formFields.length;
      final nextField = hasNext ? formFields[i + 1] : null;
      final canGroupNext =
          hasNext && nextField != null && _canGroupInRow(nextField);
      final sameSection = hasNext &&
          nextField != null &&
          nextField['section'] == field['section'];
      final areRelated = hasNext &&
          nextField != null &&
          _areRelatedFields(fieldName, nextField['field_name'] as String);

      if (canGroupInRow &&
          canGroupNext &&
          sameSection &&
          (areRelated || fieldType == 'text')) {
        // Group two fields in a row
        formWidgets.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFieldWidgetFromData(formFields[i])),
              const SizedBox(width: 12),
              Expanded(child: _buildFieldWidgetFromData(formFields[i + 1])),
            ],
          ),
        );
        i += 2; // Skip next field as it's already added
      } else {
        // Add single field
        formWidgets.add(_buildFieldWidgetFromData(field));
        i += 1;
      }

      formWidgets.add(const SizedBox(height: 16));
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: formWidgets,
      ),
    );
  }

  Widget _buildFieldWidget({
    required String fieldName,
    required String label,
    required bool required,
    required String fieldType,
    String? helpText,
    String? placeholder,
    required Map<String, dynamic> field,
  }) {
    final controller = fieldControllers[fieldName]!;
    final validationRules = field['validation_rules'] as Map<String, dynamic>?;
    final maxLengthValue = validationRules?['max_length'];
    final maxLength = maxLengthValue != null
        ? (maxLengthValue is int
            ? maxLengthValue
            : int.tryParse(maxLengthValue.toString()))
        : null;

    // Smart field type detection based on field name patterns
    String detectedType = fieldType;

    // Detect date fields by name pattern
    if (fieldType == 'text' &&
        (fieldName.contains('_date') ||
            fieldName.endsWith('_day') ||
            fieldName.endsWith('_month') ||
            fieldName.endsWith('_year'))) {
      // Check if it's asking for a full date or just day/month/year components
      if (fieldName.contains('_day') ||
          fieldName.contains('_month') ||
          fieldName.contains('_year')) {
        // Keep as text for date components (day, month, year separately)
        detectedType = 'text';
      } else if (fieldName.contains('_date') &&
          !fieldName.contains('_day') &&
          !fieldName.contains('_month') &&
          !fieldName.contains('_year')) {
        // Full date field
        detectedType = 'date';
      }
    }

    // Detect number fields by name pattern
    if (fieldType == 'text' &&
        (fieldName.contains('_amount') ||
            fieldName.contains('_number') ||
            fieldName.contains('_hours') ||
            fieldName.contains('_days') ||
            fieldName.contains('_period') ||
            fieldName.contains('_count') ||
            fieldName.contains('salary') ||
            fieldName.contains('allowance'))) {
      detectedType = 'number';
    }

    switch (detectedType) {
      case 'dropdown':
      case 'select':
        // Safe cast handling for options array which can come in various formats
        final optionsRaw = selectedLanguage == 'sw' && field['options_sw'] != null && (field['options_sw'] as List).isNotEmpty
            ? field['options_sw']
            : (field['options'] ?? []);
            
        final List<String> optionsList = (optionsRaw as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();

        // Ensure current value in controller is valid, or empty it
        if (controller.text.isNotEmpty && !optionsList.contains(controller.text)) {
           controller.text = ''; // Clear invalid selection when language/options change
        }

        return DropdownButtonFormField<String>(
          value: controller.text.isNotEmpty ? controller.text : null,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
            hintText: placeholder ?? helpText ?? 'Select an option',
            helperText: helpText,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            suffixIcon: required ? const Icon(Icons.star, size: 12, color: Colors.red) : null,
          ),
          items: optionsList.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              controller.text = newValue;
              // Trigger a state update so the UI reflects the change if needed elsewhere
              // Though TextEditingController usually handles its own updates for text fields, 
              // for dropdowns it's good practice to ensure the broader form knows.
              setState(() {}); 
            }
          },
          validator: required ? (value) => value == null || value.isEmpty ? 'This field is required' : null : null,
        );

      case 'radio':
        final optionsRaw = selectedLanguage == 'sw' && field['options_sw'] != null && (field['options_sw'] as List).isNotEmpty
            ? field['options_sw']
            : (field['options'] ?? []);
            
        final List<String> optionsList = (optionsRaw as List).map((e) => e.toString()).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (required) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 10, color: Colors.red),
                ]
              ],
            ),
            if (helpText != null && helpText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  helpText,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              )
            else
              const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: optionsList.map((String option) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    dense: true,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    leading: Radio<String>(
                      value: option,
                      groupValue: controller.text,
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            controller.text = value;
                          });
                        }
                      },
                    ),
                    onTap: () {
                      setState(() {
                        controller.text = option;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            // Hidden text field just for validation purposes
            if (required)
              SizedBox(
                height: 0,
                child: TextFormField(
                  controller: controller,
                  validator: (value) => value?.isEmpty ?? true ? 'Please select an option' : null,
                ),
              ),
          ],
        );

      case 'checkbox':
        // Ensure controller has a default boolean-like state string
        if (controller.text != 'true' && controller.text != 'false') {
          controller.text = 'false';
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: CheckboxListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (required) const Icon(Icons.star, size: 10, color: Colors.red),
              ],
            ),
            subtitle: helpText != null && helpText.isNotEmpty 
                ? Text(helpText, style: TextStyle(color: Colors.grey[500], fontSize: 12))
                : null,
            value: controller.text == 'true',
            onChanged: (bool? value) {
              setState(() {
                controller.text = (value ?? false).toString();
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        );

      case 'signature':
        final sigController = signatureControllers[fieldName];
        if (sigController == null) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (required) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 10, color: Colors.red),
                ]
              ],
            ),
            if (helpText != null && helpText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  helpText,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              )
            else
              const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey.shade100,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    child: Signature(
                      controller: sigController,
                      height: 150,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                      color: Colors.grey.shade100,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          placeholder ?? 'Sign above',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        TextButton.icon(
                          onPressed: () => sigController.clear(),
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'textarea':
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
            hintText: placeholder ?? helpText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            helperText: helpText,
            helperStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            suffixIcon: required
                ? const Icon(Icons.star, size: 12, color: Colors.red)
                : null,
          ),
          maxLines: 4,
          maxLength: maxLength,
          validator: required
              ? (value) =>
                  value?.isEmpty ?? true ? 'This field is required' : null
              : null,
        );

      case 'email':
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
            hintText: placeholder ?? helpText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            helperText: helpText,
            helperStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.email_outlined),
            suffixIcon: required
                ? const Icon(Icons.star, size: 12, color: Colors.red)
                : null,
          ),
          keyboardType: TextInputType.emailAddress,
          maxLength: maxLength,
          validator: (value) {
            if (required && (value?.isEmpty ?? true)) {
              return 'This field is required';
            }
            if (value != null && value.isNotEmpty) {
              final emailRegex =
                  RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email';
              }
            }
            return null;
          },
        );

      case 'date':
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
            hintText: placeholder ?? 'Select a date (YYYY-MM-DD)',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            helperText: helpText,
            helperStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            suffixIcon: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 if (controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => setState(() => controller.clear()),
                    ),
                 if (required) const Icon(Icons.star, size: 12, color: Colors.red),
                 const SizedBox(width: 8),
               ],
            ),
          ),
          readOnly: true,
          onTap: () async {
            // Parse existing date if any to open picker at right month
            DateTime initialDate = DateTime.now();
            if (controller.text.isNotEmpty) {
              try {
                initialDate = DateTime.parse(controller.text);
              } catch (_) {}
            }
          
            final date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                controller.text =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              });
            }
          },
          validator: required
              ? (value) =>
                  value?.isEmpty ?? true ? 'This field is required' : null
              : null,
        );

      case 'number':
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
            hintText: placeholder ?? helpText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            helperText: helpText,
            helperStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            suffixIcon: required
                ? const Icon(Icons.star, size: 12, color: Colors.red)
                : null,
          ),
          keyboardType: TextInputType.number,
          maxLength: maxLength,
          validator: required
              ? (value) =>
                  value?.isEmpty ?? true ? 'This field is required' : null
              : null,
        );

      case 'text':
      default:
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
            hintText: placeholder ?? helpText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            helperText: helpText,
            helperStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            suffixIcon: required
                ? const Icon(Icons.star, size: 12, color: Colors.red)
                : null,
          ),
          maxLength: maxLength,
          validator: required
              ? (value) =>
                  value?.isEmpty ?? true ? 'This field is required' : null
              : null,
        );
    }
  }

  // Helper method to build field widget from field data
  Widget _buildFieldWidgetFromData(Map<String, dynamic> field) {
    final fieldName = field['field_name'] as String;
    final label = selectedLanguage == 'sw'
        ? (field['label_sw'] as String? ?? fieldName)
        : (field['label_en'] as String? ?? fieldName);
    final required = field['is_required'] as bool? ?? false;
    final fieldType = field['field_type'] as String? ?? 'text';
    final helpText = selectedLanguage == 'sw'
        ? (field['help_text_sw'] as String?)
        : (field['help_text_en'] as String?);
    final placeholder = selectedLanguage == 'sw'
        ? (field['placeholder_sw'] as String?)
        : (field['placeholder_en'] as String?);

    return _buildFieldWidget(
      fieldName: fieldName,
      label: label,
      required: required,
      fieldType: fieldType,
      helpText: helpText,
      placeholder: placeholder,
      field: field,
    );
  }

  // Check if a field can be grouped in a row (only short text fields)
  bool _canGroupInRow(Map<String, dynamic> field) {
    final fieldType = field['field_type'] as String? ?? 'text';

    // Only text fields can be grouped (not textarea, email, date pickers)
    if (fieldType != 'text') return false;

    final fieldName = field['field_name'] as String;
    final label = field['label_en'] as String? ?? '';

    // Don't group if it's a full date field (will use date picker)
    if (fieldName.contains('_date') &&
        !fieldName.contains('_day') &&
        !fieldName.contains('_month') &&
        !fieldName.contains('_year')) {
      return false;
    }

    // Don't group fields that typically contain long text
    final longFieldPatterns = [
      'name', // Names can be long (employee_name, company_name, etc.)
      'address', // Addresses are typically long
      'title', // Job titles, document titles can be long
      'position', // Position names can be long
      'description', // Descriptions are always long
      'reason', // Reasons/explanations can be long
      'subject', // Subject lines can be long
      'location', // Locations can be long
      'department', // Department names can be long
      'qualification', // Qualifications can be long
      'email', // Email addresses can be long
      'phone', // Phone numbers with extensions
      'street', // Street names/addresses
      'city', // City names can sometimes be long
      'region', // Region names can be long
      'district', // District names
    ];

    // Check if field name or label contains any long field patterns
    final fieldNameLower = fieldName.toLowerCase();
    final labelLower = label.toLowerCase();

    for (final pattern in longFieldPatterns) {
      if (fieldNameLower.contains(pattern) || labelLower.contains(pattern)) {
        return false; // Don't group long fields
      }
    }

    // Only group very short fields like:
    // - Date components (day, month, year)
    // - Short codes (code, id, number without context)
    // - Short numeric values (age, count, quantity)
    final shortFieldPatterns = [
      '_day', '_month', '_year', // Date components
      '_code', '_id', // Short codes/IDs
      'age', 'quantity', 'count', // Short numbers
      'hours', 'minutes', // Time components
      'po_box', 'zip', 'postal', // Short location codes
    ];

    for (final pattern in shortFieldPatterns) {
      if (fieldNameLower.contains(pattern)) {
        return true; // Safe to group these
      }
    }

    // Default: don't group unless explicitly identified as short
    return false;
  }

  // Check if two fields are related (e.g., date components)
  bool _areRelatedFields(String field1, String field2) {
    // Extract base field name (remove suffixes like _day, _month, _year)
    final base1 = field1.replaceAll(RegExp(r'_(day|month|year|date)$'), '');
    final base2 = field2.replaceAll(RegExp(r'_(day|month|year|date)$'), '');

    // If base names match, they're related (e.g., contract_start_day and contract_start_month)
    if (base1 == base2 && base1.isNotEmpty) return true;

    // Check for common date patterns
    if ((field1.contains('_day') && field2.contains('_month')) ||
        (field1.contains('_month') && field2.contains('_year')) ||
        (field1.contains('_day') && field2.contains('_year'))) {
      return base1 == base2;
    }

    return false;
  }
}
