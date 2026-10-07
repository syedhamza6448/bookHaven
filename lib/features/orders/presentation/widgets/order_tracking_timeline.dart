import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/orders/presentation/widgets/order_status_badge.dart';
import 'package:bookhaven/shared/models/order_status_event.dart';

class _StepData {
  const _StepData(this.status, this.time, this.done, this.current);
  final String status;
  final DateTime? time;
  final bool done;
  final bool current;
}

class OrderTrackingTimeline extends StatelessWidget {
  const OrderTrackingTimeline({
    super.key,
    required this.status,
    required this.events,
  });

  final String status;
  final List<OrderStatusEvent> events;

  static const _flow = [
    'placed',
    'processing',
    'shipped',
    'out_for_delivery',
    'delivered',
  ];

  static const _hints = {
    'placed': 'We have received your order',
    'processing': 'Your books are being packed',
    'shipped': 'On its way to your city',
    'out_for_delivery': 'Arriving today',
    'delivered': 'Enjoy your reading',
    'cancelled': 'This order was cancelled',
  };

  DateTime? _timeFor(String s) {
    for (final e in events.reversed) {
      if (e.status == s) return e.createdAt;
    }
    return null;
  }

  List<_StepData> _steps() {
    if (status == 'cancelled') {
      if (events.isEmpty) {
        return const [_StepData('cancelled', null, true, true)];
      }
      return [
        for (var i = 0; i < events.length; i++)
          _StepData(
            events[i].status,
            events[i].createdAt,
            true,
            i == events.length - 1,
          ),
      ];
    }
    final currentIndex = _flow.indexOf(status).clamp(0, _flow.length - 1);
    return [
      for (var i = 0; i < _flow.length; i++)
        _StepData(
          _flow[i],
          _timeFor(_flow[i]),
          i <= currentIndex,
          i == currentIndex,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps();
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            data: steps[i],
            isLast: i == steps.length - 1,
            nextDone: i + 1 < steps.length && steps[i + 1].done,
            cancelled: status == 'cancelled',
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.data,
    required this.isLast,
    required this.nextDone,
    required this.cancelled,
  });

  final _StepData data;
  final bool isLast;
  final bool nextDone;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final isCancelStep = data.status == 'cancelled';
    final activeColor = isCancelStep ? c.error : c.primary;

    final circle = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: data.done ? activeColor : c.surface,
        border: Border.all(
          color: data.current && !isCancelStep
              ? c.accent
              : (data.done ? activeColor : c.border),
          width: data.current ? 2.5 : 1.5,
        ),
      ),
      child: Icon(
        OrderStatusBadge.iconFor(data.status),
        size: 16,
        color: data.done ? Colors.white : c.textSecondary,
      ),
    );

    final time = data.time == null
        ? null
        : DateFormat('d MMM, h:mm a').format(data.time!);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                circle,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: nextDone && !cancelled ? c.primary : c.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    OrderStatusBadge.labelFor(data.status),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: data.current
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: data.done || data.current
                          ? c.textPrimary
                          : c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time ??
                        (data.done
                            ? OrderTrackingTimeline._hints[data.status] ?? ''
                            : 'Pending'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: c.textSecondary),
                  ),
                  if (time != null && data.current) ...[
                    const SizedBox(height: 2),
                    Text(
                      OrderTrackingTimeline._hints[data.status] ?? '',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: c.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
