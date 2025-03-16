import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';
import 'package:gigways/core/widgets/app_button.dart';
import 'package:intl/intl.dart';

enum TrackerState { inactive, active, endingShift }

class TrackerData {
  final double hours;
  final int miles;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? earnings;
  final double? expenses;

  TrackerData({
    required this.hours,
    required this.miles,
    this.startTime,
    this.endTime,
    this.earnings,
    this.expenses,
  });

  TrackerData copyWith({
    double? hours,
    int? miles,
    DateTime? startTime,
    DateTime? endTime,
    double? earnings,
    double? expenses,
  }) {
    return TrackerData(
      hours: hours ?? this.hours,
      miles: miles ?? this.miles,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      earnings: earnings ?? this.earnings,
      expenses: expenses ?? this.expenses,
    );
  }
}

class TrackerCard extends StatefulWidget {
  final bool isTrackerEnabled;
  final TrackerData trackerData;
  final int drivingNow;
  final int totalDrivers;
  final Function(bool) onTrackerToggled;
  final Function(double earnings, double expenses) onShiftEnded;

  const TrackerCard({
    Key? key,
    required this.isTrackerEnabled,
    required this.trackerData,
    required this.drivingNow,
    required this.totalDrivers,
    required this.onTrackerToggled,
    required this.onShiftEnded,
  }) : super(key: key);

  @override
  State<TrackerCard> createState() => _TrackerCardState();
}

class _TrackerCardState extends State<TrackerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  TrackerState _currentState = TrackerState.inactive;
  final TextEditingController _earningsController = TextEditingController();
  final TextEditingController _expensesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentState =
        widget.isTrackerEnabled ? TrackerState.active : TrackerState.inactive;

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Set up animations
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeInOutCubic));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(TrackerCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If tracker was enabled and now it's disabled, show the earnings form
    if (oldWidget.isTrackerEnabled && !widget.isTrackerEnabled) {
      _showEarningsForm();
    } else if (!oldWidget.isTrackerEnabled && widget.isTrackerEnabled) {
      // If tracker was disabled and now it's enabled
      setState(() {
        _currentState = TrackerState.active;
      });
    }
  }

  void _showEarningsForm() {
    setState(() {
      _currentState = TrackerState.endingShift;
    });
    _animationController.forward();
  }

  void _hideEarningsForm() {
    _animationController.reverse().then((_) {
      setState(() {
        _currentState = TrackerState.inactive;
      });
    });
  }

  void _saveEarnings() {
    if (_formKey.currentState?.validate() ?? false) {
      final earnings = double.tryParse(_earningsController.text) ?? 0.0;
      final expenses = double.tryParse(_expensesController.text) ?? 0.0;

      // Send data back to parent
      widget.onShiftEnded(earnings, expenses);

      // Reset form and animate back to inactive state
      _earningsController.clear();
      _expensesController.clear();
      _hideEarningsForm();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _earningsController.dispose();
    _expensesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        children: [
          // Status Header
          _buildStatusHeader(),

          // Content based on current state
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _currentState == TrackerState.endingShift
                ? _buildEarningsForm()
                : _buildTrackerContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _currentState == TrackerState.active
            ? AppColorToken.golden.value
            : Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _getHeaderIcon(),
                color: _currentState == TrackerState.active
                    ? AppColorToken.black.value
                    : AppColorToken.white.value,
                size: 20,
              ),
              8.horizontalSpace,
              Text(
                _getHeaderText(),
                style: AppTextStyle.size(16).medium.withColor(
                      _currentState == TrackerState.active
                          ? AppColorToken.black
                          : AppColorToken.white,
                    ),
              ),
            ],
          ),
          if (_currentState != TrackerState.endingShift)
            Switch(
              value: _currentState == TrackerState.active,
              onChanged: widget.onTrackerToggled,
              activeColor: AppColorToken.black.value,
              inactiveThumbColor: AppColorToken.white.value,
              activeTrackColor: AppColorToken.black.value.withAlpha(150),
              inactiveTrackColor: AppColorToken.white.value.withAlpha(50),
            )
        ],
      ),
    );
  }

  IconData _getHeaderIcon() {
    switch (_currentState) {
      case TrackerState.active:
        return Icons.location_on;
      case TrackerState.inactive:
        return Icons.location_off;
      case TrackerState.endingShift:
        return Icons.monetization_on;
    }
  }

  String _getHeaderText() {
    switch (_currentState) {
      case TrackerState.active:
        return 'Tracker Active';
      case TrackerState.inactive:
        return 'Tracker Inactive';
      case TrackerState.endingShift:
        return 'Shift Completed';
    }
  }

  Widget _buildTrackerContent() {
    return Padding(
      key: const ValueKey<String>('tracker_content'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status message
          Text(
            _currentState == TrackerState.active
                ? 'End Shift: Turn off Tracker!'
                : 'Start tracking your hours and miles',
            style: AppTextStyle.size(16).bold.withColor(
                _currentState == TrackerState.active
                    ? AppColorToken.golden
                    : AppColorToken.white),
          ),
          16.verticalSpace,

          // Hours and miles
          Row(
            children: [
              Icon(
                Icons.access_time_filled,
                color: AppColorToken.golden.value,
                size: 20,
              ),
              8.horizontalSpace,
              Text(
                '${widget.trackerData.hours.toStringAsFixed(2)} hr',
                style:
                    AppTextStyle.size(16).medium.withColor(AppColorToken.white),
              ),
              24.horizontalSpace,
              Icon(
                Icons.directions_car,
                color: AppColorToken.golden.value,
                size: 20,
              ),
              8.horizontalSpace,
              Text(
                '${widget.trackerData.miles} mi',
                style:
                    AppTextStyle.size(16).medium.withColor(AppColorToken.white),
              ),
            ],
          ),
          16.verticalSpace,

          // Start and end time
          if (_currentState == TrackerState.active &&
              widget.trackerData.startTime != null)
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    label: 'Started',
                    time: widget.trackerData.startTime!,
                  ),
                ),
                16.horizontalSpace,
                Expanded(
                  child: _buildTimeCard(
                    label: 'Est. End',
                    time: widget.trackerData.startTime!
                        .add(const Duration(hours: 8)),
                  ),
                ),
              ],
            ),

          // CTA Button for tracking
          if (_currentState == TrackerState.inactive) ...[
            16.verticalSpace,
            AppButton(
              text: 'Start Tracking',
              onPressed: () => widget.onTrackerToggled(true),
            ),
          ],

          16.verticalSpace,

          // Status line
          // Container(
          //   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          //   decoration: BoxDecoration(
          //     color: AppColorToken.golden.value.withAlpha(10),
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Text(
          //         'Georgia:',
          //         style: AppTextStyle.size(14)
          //             .medium
          //             .withColor(AppColorToken.white),
          //       ),
          //       RichText(
          //         text: TextSpan(
          //           style: AppTextStyle.size(14)
          //               .medium
          //               .withColor(AppColorToken.white),
          //           children: [
          //             TextSpan(
          //               text: widget.drivingNow.toString(),
          //               style: TextStyle(
          //                 color: AppColorToken.golden.value,
          //               ),
          //             ),
          //             const TextSpan(text: ' / '),
          //             TextSpan(text: widget.totalDrivers.toString()),
          //             const TextSpan(text: ' driving right now!'),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildEarningsForm() {
    return AnimatedBuilder(
      key: const ValueKey<String>('earnings_form'),
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(
                0, _slideAnimation.value * (1 - _opacityAnimation.value)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Great job! Your shift is complete.',
                      style: AppTextStyle.size(16)
                          .bold
                          .withColor(AppColorToken.white),
                    ),
                    8.verticalSpace,
                    Text(
                      'Please enter your earnings and expenses for this shift:',
                      style: AppTextStyle.size(14)
                          .regular
                          .withColor(AppColorToken.white..color.withAlpha(70)),
                    ),
                    16.verticalSpace,

                    // Shift Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColorToken.black.value.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColorToken.golden.value.withAlpha(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hours Worked:',
                                style: AppTextStyle.size(14)
                                    .medium
                                    .withColor(AppColorToken.white),
                              ),
                              Text(
                                '${widget.trackerData.hours.toStringAsFixed(2)} hours',
                                style: AppTextStyle.size(14)
                                    .bold
                                    .withColor(AppColorToken.golden),
                              ),
                            ],
                          ),
                          8.verticalSpace,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Miles Driven:',
                                style: AppTextStyle.size(14)
                                    .medium
                                    .withColor(AppColorToken.white),
                              ),
                              Text(
                                '${widget.trackerData.miles} miles',
                                style: AppTextStyle.size(14)
                                    .bold
                                    .withColor(AppColorToken.golden),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    20.verticalSpace,

                    // Earnings Input
                    _buildCurrencyInput(
                      label: 'Earnings (\$)',
                      controller: _earningsController,
                      icon: Icons.attach_money,
                    ),
                    16.verticalSpace,

                    // Expenses Input
                    _buildCurrencyInput(
                      label: 'Expenses (\$)',
                      controller: _expensesController,
                      icon: Icons.receipt_long,
                    ),
                    24.verticalSpace,

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Skip',
                            onPressed: _hideEarningsForm,
                            backgroundColor: Colors.grey[800],
                            textColor: AppColorToken.white.value,
                          ),
                        ),
                        16.horizontalSpace,
                        Expanded(
                          child: AppButton(
                            text: 'Save',
                            onPressed: _saveEarnings,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeCard({required String label, required DateTime time}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColorToken.black.value,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.size(12)
                .regular
                .withColor(AppColorToken.white..color.withAlpha(70)),
          ),
          4.verticalSpace,
          Text(
            DateFormat('h:mm a').format(time),
            style: AppTextStyle.size(16).bold.withColor(AppColorToken.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: AppTextStyle.size(16).medium.withColor(AppColorToken.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyle.size(14)
            .regular
            .withColor(AppColorToken.white..color.withAlpha(70)),
        prefixIcon: Icon(
          icon,
          color: AppColorToken.golden.value,
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColorToken.white.value.withAlpha(30),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColorToken.white.value.withAlpha(30),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColorToken.golden.value,
          ),
        ),
        filled: true,
        fillColor: AppColorToken.black.value.withAlpha(50),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }
}
