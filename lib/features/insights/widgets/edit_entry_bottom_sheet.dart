import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:gigways/features/insights/models/insight_entry.dart';
import 'package:gigways/features/insights/widgets/value_selector_sheet.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';

class EditEntryBottomSheet extends StatefulWidget {
  final InsightEntry entry;
  final TrackingSession session;
  final Function(TrackingSession session, {
    required double miles,
    required double hours,
    required double earnings,
    required double expenses,
  }) onUpdate;

  const EditEntryBottomSheet({
    Key? key,
    required this.entry,
    required this.session,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditEntryBottomSheet> createState() => _EditEntryBottomSheetState();

  /// Static method to show the bottom sheet
  static Future<void> show(
    BuildContext context,
    InsightEntry entry,
    TrackingSession session,
    Function(TrackingSession session, {
      required double miles,
      required double hours,
      required double earnings,
      required double expenses,
    }) onUpdate,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => EditEntryBottomSheet(
        entry: entry,
        session: session,
        onUpdate: onUpdate,
      ),
    );
  }
}

class _EditEntryBottomSheetState extends State<EditEntryBottomSheet> {
  late double _selectedMiles;
  late double _selectedHours;
  late TextEditingController _earningsController;
  late TextEditingController _expensesController;

  @override
  void initState() {
    super.initState();
    // Initialize values from entry
    _selectedMiles = widget.entry.miles;
    _selectedHours = widget.entry.hours;
    _earningsController = TextEditingController(text: widget.entry.earnings.toStringAsFixed(2));
    _expensesController = TextEditingController(text: widget.entry.expenses.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _earningsController.dispose();
    _expensesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColorToken.black.value,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(50),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle for better UX
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColorToken.white.value.withAlpha(50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              16.verticalSpace,
              
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: AppColorToken.golden.value,
                        size: 20,
                      ),
                      12.horizontalSpace,
                      Text(
                        'Edit Entry',
                        style: AppTextStyle.size(18)
                            .bold
                            .withColor(AppColorToken.golden),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColorToken.white.value,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              16.verticalSpace,

              // Date and time info (non-editable)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorToken.black.value.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColorToken.white.value.withAlpha(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Date: ',
                          style: AppTextStyle.size(14).regular.withColor(
                              AppColorToken.white..color.withAlpha(180)),
                        ),
                        Text(
                          widget.entry.date,
                          style: AppTextStyle.size(14)
                              .medium
                              .withColor(AppColorToken.white),
                        ),
                      ],
                    ),
                    8.verticalSpace,
                    Row(
                      children: [
                        Text(
                          'Time: ',
                          style: AppTextStyle.size(14).regular.withColor(
                              AppColorToken.white..color.withAlpha(180)),
                        ),
                        Text(
                          widget.entry.time,
                          style: AppTextStyle.size(14)
                              .medium
                              .withColor(AppColorToken.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              20.verticalSpace,

              // Miles selector button
              GestureDetector(
                onTap: () async {
                  final value = await MilesSelectorSheet.show(
                    context: context,
                    initialValue: _selectedMiles,
                  );
                  
                  if (value != null) {
                    setState(() {
                      _selectedMiles = value;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColorToken.black.value.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColorToken.golden.value.withAlpha(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: AppColorToken.golden.value,
                        size: 24,
                      ),
                      16.horizontalSpace,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Miles',
                            style: AppTextStyle.size(14)
                                .regular
                                .withColor(AppColorToken.white..color.withAlpha(70)),
                          ),
                          4.verticalSpace,
                          Text(
                            '${_selectedMiles.toStringAsFixed(1)} mi',
                            style: AppTextStyle.size(18)
                                .medium
                                .withColor(AppColorToken.white),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColorToken.golden.value,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              16.verticalSpace,

              // Hours selector button
              GestureDetector(
                onTap: () async {
                  final value = await HoursSelectorSheet.show(
                    context: context,
                    initialValue: _selectedHours,
                  );
                  
                  if (value != null) {
                    setState(() {
                      _selectedHours = value;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColorToken.black.value.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColorToken.golden.value.withAlpha(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColorToken.golden.value,
                        size: 24,
                      ),
                      16.horizontalSpace,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hours',
                            style: AppTextStyle.size(14)
                                .regular
                                .withColor(AppColorToken.white..color.withAlpha(70)),
                          ),
                          4.verticalSpace,
                          Text(
                            '${_selectedHours.toStringAsFixed(2)} hrs',
                            style: AppTextStyle.size(18)
                                .medium
                                .withColor(AppColorToken.white),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColorToken.golden.value,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              16.verticalSpace,

              // Earnings field
              _buildCurrencyField(
                context: context,
                label: 'Earnings (\$)',
                controller: _earningsController,
                icon: Icons.attach_money,
              ),
              12.verticalSpace,

              // Expenses field
              _buildCurrencyField(
                context: context,
                label: 'Expenses (\$)',
                controller: _expensesController,
                icon: Icons.receipt_long,
              ),
              24.verticalSpace,

              // Action button
              AppButton(
                text: 'Save Changes',
                onPressed: _saveChanges,
              ),
              24.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() {
    // Parse the entered values
    final miles = _selectedMiles;
    final hours = _selectedHours;
    final earnings = double.tryParse(_earningsController.text) ?? widget.entry.earnings;
    final expenses = double.tryParse(_expensesController.text) ?? widget.entry.expenses;

    // Update the session with the new values
    widget.onUpdate(
      widget.session,
      miles: miles,
      hours: hours,
      earnings: earnings,
      expenses: expenses,
    );

    Navigator.pop(context);
  }

  // Enhanced Currency Field with better UX
  Widget _buildCurrencyField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.size(16).medium.withColor(AppColorToken.white),
        ),
        8.verticalSpace,
        Container(
          decoration: BoxDecoration(
            color: AppColorToken.black.value.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColorToken.golden.value.withAlpha(30),
            ),
          ),
          child: TextField(
            controller: controller,
            style: AppTextStyle.size(18).regular.withColor(AppColorToken.white),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: AppColorToken.golden.value,
                size: 24,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              // Format the value as currency if needed
              if (value.isNotEmpty) {
                // Only if there's a decimal and we have 3+ decimal places
                if (value.contains('.') && value.split('.')[1].length > 2) {
                  final numericValue = double.tryParse(value);
                  if (numericValue != null) {
                    controller.text = numericValue.toStringAsFixed(2);
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  }
                }
              }
            },
          ),
        ),
      ],
    );
  }
}