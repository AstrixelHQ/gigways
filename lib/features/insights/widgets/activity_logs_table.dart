import 'package:flutter/material.dart';
import 'package:gigways/core/extensions/sizing_extension.dart';
import 'package:gigways/core/theme/themes.dart';

class ActivityLogItem {
  final String date;
  final List<String> values;

  ActivityLogItem({
    required this.date,
    required this.values,
  });
}

class ActivityLogsTable extends StatelessWidget {
  final String title;
  final List<ActivityLogItem> logs;
  final List<String> columns;

  const ActivityLogsTable({
    super.key,
    required this.title,
    required this.logs,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyle.size(18).bold.withColor(AppColorToken.golden),
        ),
        16.verticalSpace,

        // Empty state if no logs
        if (logs.isEmpty) _buildEmptyState() else _buildTable(context),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColorToken.black.value.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorToken.golden.value.withAlpha(20),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 48,
              color: AppColorToken.white.value.withAlpha(100),
            ),
            16.verticalSpace,
            Text(
              'No activity logs available',
              style:
                  AppTextStyle.size(16).medium.withColor(AppColorToken.white),
            ),
            8.verticalSpace,
            Text(
              'Start tracking to see your activity here',
              style: AppTextStyle.size(14).regular.withColor(
                    AppColorToken.white..color.withAlpha(70),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColorToken.black.value.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColorToken.golden.value.withAlpha(20),
          ),
        ),
        child: Column(
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColorToken.black.value.withAlpha(50),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColorToken.golden.value.withAlpha(30),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Date column
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Date',
                      style: AppTextStyle.size(14)
                          .semiBold
                          .withColor(AppColorToken.golden),
                    ),
                  ),

                  // Dynamic columns based on the provided list
                  ...List.generate(columns.length - 1, (index) {
                    return Expanded(
                      flex: index == columns.length - 2
                          ? 1
                          : 2, // Last column (often amount) gets less space
                      child: Text(
                        columns[index + 1],
                        style: AppTextStyle.size(14)
                            .semiBold
                            .withColor(AppColorToken.golden),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Table body
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final item = logs[index];
                  final isLastItem = index == logs.length - 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: isLastItem
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: AppColorToken.white.value.withAlpha(10),
                                width: 1,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        // Date column
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.date,
                            style: AppTextStyle.size(14)
                                .medium
                                .withColor(AppColorToken.white),
                          ),
                        ),

                        // Dynamic value columns
                        ...List.generate(item.values.length, (valueIndex) {
                          final bool isAmountColumn =
                              valueIndex == item.values.length - 1 &&
                                  item.values[valueIndex].contains('\$');

                          return Expanded(
                            flex: isAmountColumn ? 1 : 2,
                            child: Text(
                              item.values[valueIndex],
                              style: AppTextStyle.size(14).regular.withColor(
                                    isAmountColumn
                                        ? (item.values[valueIndex]
                                                .startsWith('-')
                                            ? AppColorToken.golden
                                            : AppColorToken.golden)
                                        : AppColorToken.white,
                                  ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
