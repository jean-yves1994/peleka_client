import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/peleka_button.dart';
import '../data/location_repository.dart';
import 'location_verification_map.dart';

Future<PlaceResult?> showLocationVerificationSheet({
  required BuildContext context,
  required LocationRepository repository,
  required PlaceResult candidate,
  required String title,
  required String locationType,
}) async {
  double lat = candidate.lat;
  double lng = candidate.lng;
  double? accuracyMeters = candidate.accuracyMeters;
  bool confirming = false;

  return showModalBottomSheet<PlaceResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> confirm() async {
            if (confirming) return;
            setSheetState(() => confirming = true);
            try {
              final verified = await repository.verify(
                lat: lat,
                lng: lng,
                locationType: locationType,
                inputText: candidate.name.isNotEmpty ? candidate.name : candidate.address,
                accuracyMeters: accuracyMeters,
              );
              if (context.mounted) Navigator.of(context).pop(verified);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceAll('ApiException: ', '')),
                  backgroundColor: AppColors.error,
                ),
              );
              setSheetState(() => confirming = false);
            }
          }

          return SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LocationVerificationMap(
                    candidate: candidate,
                    title: 'Confirm $title location',
                    subtitle: 'Adjust the pin to the exact pickup or delivery point.',
                    onReverse: repository.reverse,
                    onChanged: (newLat, newLng, accuracy) {
                      lat = newLat;
                      lng = newLng;
                      accuracyMeters = accuracy ?? accuracyMeters;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: PelekaButton(
                            label: 'Cancel',
                            outlined: true,
                            onPressed: confirming ? null : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PelekaButton(
                            label: confirming ? 'Confirming…' : 'Confirm location',
                            icon: Icons.check,
                            loading: confirming,
                            onPressed: confirming ? null : confirm,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
