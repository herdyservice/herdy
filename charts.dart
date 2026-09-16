import 'package:flutter/material.dart';

double _clampD(double value, double min, double max) {
  if (max < min) return min;
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

/// Histogramme simple (durées de cycle, etc.).
class SimpleBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final String unit;

  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.unit = 'j',
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final base = (minV - 4) < 0 ? 0.0 : (minV - 4);
    final span = (maxV - base) <= 0 ? 1.0 : (maxV - base);

    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final ratio = (values[i] - base) / span;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${values[i].toStringAsFixed(0)}$unit',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            height: _clampD(
                                c.maxHeight * (0.15 + 0.85 * ratio),
                                6.0,
                                c.maxHeight),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  color.withOpacity(0.55),
                                  color,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels.length > i ? labels[i] : '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Barres horizontales de fréquence (symptômes, humeurs).
class FrequencyBars extends StatelessWidget {
  final List<MapEntry<String, int>> data;
  final Color color;

  const FrequencyBars({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text(
        'Pas encore de données.',
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      );
    }
    final max = data.first.value;
    return Column(
      children: data.map((e) {
        final ratio = max == 0 ? 0.0 : e.value / max;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(e.key,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text('${e.value}×',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Anneau de progression du cycle.
class CycleRing extends StatelessWidget {
  final int day;
  final int total;
  final Color color;
  final Widget child;

  const CycleRing({
    super.key,
    required this.day,
    required this.total,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (day / total).clamp(0.0, 1.0);
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 12,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
