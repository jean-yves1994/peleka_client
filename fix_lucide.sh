#!/usr/bin/env bash
# ============================================================
# fix_lucide.sh — remove lucide_icons from the Peleka app.
# Run from the project root:  bash fix_lucide.sh
# - deletes the lucide import line from every file
# - maps every LucideIcons.<name> to a Material Icons.<name>
# - removes lucide from pubspec.yaml
# ============================================================
set -e
cd "$(dirname "$0")"

# macOS needs `sed -i ''`; Linux/Git-Bash use `sed -i`
if [[ "$OSTYPE" == "darwin"* ]]; then SEDI=(sed -i ''); else SEDI=(sed -i); fi

# LucideIcons.<lucide>  →  Icons.<material>
declare -A MAP=(
  [home]="home_outlined"
  [package]="inventory_2_outlined"
  [package2]="inventory_2_outlined"
  [bell]="notifications_outlined"
  [user]="person_outline"
  [lock]="lock_outline"
  [mail]="mail_outline"
  [phone]="phone_outlined"
  [smartphone]="smartphone"
  [eye]="visibility_outlined"
  [eyeOff]="visibility_off_outlined"
  [arrowRight]="arrow_forward"
  [arrowLeft]="arrow_back"
  [chevronRight]="chevron_right"
  [mapPin]="trip_origin"
  [mapPinned]="location_on"
  [stickyNote]="sticky_note_2_outlined"
  [info]="info_outline"
  [fileText]="description_outlined"
  [weight]="monitor_weight_outlined"
  [scale]="monitor_weight_outlined"
  [pen]="edit_outlined"
  [calculator]="calculate_outlined"
  [tag]="local_offer_outlined"
  [checkCircle2]="check_circle"
  [checkCheck]="done_all"
  [plus]="add"
  [filter]="filter_list"
  [route]="alt_route"
  [copy]="copy"
  [refreshCw]="refresh"
  [camera]="photo_camera_outlined"
  [star]="star"
  [xCircle]="cancel_outlined"
  [send]="send"
  [wrench]="build_outlined"
  [bike]="two_wheeler"
  [clock]="access_time"
  [wifi]="wifi"
  [helpCircle]="help_outline"
  [shieldCheck]="verified_user_outlined"
  [logOut]="logout"
  [mapPinned2]="location_on"
  [alertCircle]="error_outline"
  [checkCircle]="check_circle"
  [truck]="local_shipping_outlined"
)

FILES=$(grep -rl "lucide_icons" lib 2>/dev/null || true)
if [[ -z "$FILES" ]]; then echo "No lucide references found. Nothing to do."; else
  for f in $FILES; do
    # 1) delete the import line
    "${SEDI[@]}" "/package:lucide_icons\/lucide_icons.dart/d" "$f"
    # 2) map each icon name
    for lucide in "${!MAP[@]}"; do
      "${SEDI[@]}" "s/LucideIcons\.${lucide}\b/Icons.${MAP[$lucide]}/g" "$f"
    done
    echo "✓ fixed $f"
  done
fi

# 3) remove from pubspec (both the dep line and any stray reference)
if grep -q "lucide" pubspec.yaml 2>/dev/null; then
  "${SEDI[@]}" "/lucide_icons/d" pubspec.yaml
  echo "✓ removed lucide_icons from pubspec.yaml"
fi

echo ""
echo "Now run:"
echo "  flutter pub get && flutter run"
echo ""
echo "Any leftover LucideIcons references (should be empty):"
grep -rn "LucideIcons" lib || echo "  (none — clean!)"
