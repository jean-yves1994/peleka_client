import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/wave_background.dart';
import 'auth_view_model.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _S();
}

class _S extends ConsumerState<OnboardingScreen> {
  final _c = PageController();
  int _page = 0;
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    // Update state (onboardingSeen=true) AND persist — then go to login.
    await ref.read(authViewModelProvider.notifier).markOnboardingSeen();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        PageView(
            controller: _c,
            onPageChanged: (i) => setState(() => _page = i),
            children: const [_P3(), _P1(), _P2()]),
        Align(
            alignment: Alignment.bottomCenter,
            child: _Bar(page: _page, onStart: _start)),
        Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: TextButton(
                onPressed: _start,
                child: const Text('Skip',
                    style: TextStyle(
                        color: AppColors.ink500,
                        fontWeight: FontWeight.w600)))),
      ]));
}

class _Bar extends StatelessWidget {
  final int page;
  final VoidCallback onStart;
  const _Bar({required this.page, required this.onStart});
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 250,
      width: double.infinity,
      child: Stack(alignment: Alignment.bottomCenter, children: [
        const Positioned.fill(child: BottomWaves(height: 250)),
        Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final a = i == page;
                    return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: a ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: a
                                ? AppColors.orange
                                : Colors.white.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(999)));
                  })),
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                          onPressed: onStart,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.orange,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999))),
                          child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Get Started',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward,
                                    color: Colors.white, size: 20)
                              ])))),
            ])),
      ]));
}

class _Scaf extends StatelessWidget {
  final Widget child;
  const _Scaf({required this.child});
  @override
  Widget build(BuildContext context) => SafeArea(
      bottom: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 260), child: child));
}

class _P1 extends StatelessWidget {
  const _P1();
  @override
  Widget build(BuildContext context) => _Scaf(
          child: Column(children: [
        const Align(alignment: Alignment.topLeft, child: DottedGrid()),
        const SizedBox(height: 8),
        const Text('Delivering More\nThan Just Orders',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                height: 1.2)),
        const SizedBox(height: 12),
        RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.navy,
                    height: 1.5,
                    fontWeight: FontWeight.w500),
                children: [
                  TextSpan(text: 'Care. Convenience. '),
                  TextSpan(
                      text: 'Commitment.\n',
                      style: TextStyle(color: AppColors.ink400)),
                  TextSpan(text: "That's Peleka.")
                ])),
        const Spacer(),
        SizedBox(
            height: 150,
            child: Stack(alignment: Alignment.center, children: [
              Align(
                  alignment: const Alignment(0, -1),
                  child: _Badge(
                      icon: Icons.verified_user,
                      label: 'Secure\nDelivery',
                      color: AppColors.orange,
                      big: true)),
              Align(
                  alignment: const Alignment(-1, 0.4),
                  child: _Badge(
                      icon: Icons.access_time_filled,
                      label: 'Always\nOn Time',
                      color: AppColors.blue)),
              Align(
                  alignment: const Alignment(1, 0.4),
                  child: _Badge(
                      icon: Icons.headset_mic,
                      label: '24/7\nSupport',
                      color: AppColors.blue)),
            ])),
        const SizedBox(height: 8),
        const _Boxes(),
        const Spacer(),
      ]));
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool big;
  const _Badge(
      {required this.icon,
      required this.label,
      required this.color,
      this.big = false});
  @override
  Widget build(BuildContext context) {
    final s = big ? 60.0 : 54.0;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [color, color.withOpacity(0.75)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6))
              ]),
          child: Icon(icon, color: Colors.white, size: big ? 28 : 24)),
      const SizedBox(height: 6),
      Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              height: 1.15))
    ]);
  }
}

class _Boxes extends StatelessWidget {
  const _Boxes();
  @override
  Widget build(BuildContext context) {
    Widget box({double w = 100, double h = 70, bool label = false}) =>
        Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.orangeDark]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 6))
                ]),
            alignment: Alignment.center,
            child: label
                ? const Text('PELEKA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1))
                : null);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      box(w: 110, h: 60, label: true),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        box(w: 90, h: 60),
        const SizedBox(width: 8),
        box(w: 90, h: 60, label: true)
      ])
    ]);
  }
}

class _P2 extends StatelessWidget {
  const _P2();
  @override
  Widget build(BuildContext context) => _Scaf(
          child: Column(children: [
        const Align(alignment: Alignment.topLeft, child: DottedGrid()),
        const SizedBox(height: 8),
        const Text('Track Every Step',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.navy)),
        const SizedBox(height: 12),
        const Text('Real-time tracking keeps you\nin the know.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, color: AppColors.ink500, height: 1.5)),
        const SizedBox(height: 24),
        Expanded(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
            _Node(
                icon: Icons.inventory_2,
                label: 'Order\nConfirmed',
                color: AppColors.blue,
                connector: true),
            _Node(
                icon: Icons.two_wheeler,
                label: 'On the\nWay',
                color: AppColors.blue,
                connector: true),
            _Node(
                icon: Icons.check,
                label: 'Delivered',
                color: AppColors.orange,
                connector: false)
          ]),
          const SizedBox(width: 16),
          Expanded(child: _Phone()),
        ])),
      ]));
}

class _Node extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool connector;
  const _Node(
      {required this.icon,
      required this.label,
      required this.color,
      required this.connector});
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
            width: 46,
            height: 46,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ]),
            child: Icon(icon, color: Colors.white, size: 22)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                height: 1.1)),
        if (connector)
          Container(
              width: 2,
              height: 22,
              margin: const EdgeInsets.symmetric(vertical: 2),
              color: AppColors.ink200)
      ]);
}

class _Phone extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AspectRatio(
      aspectRatio: 0.52,
      child: Container(
          decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: AppColors.navy.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 12))
              ]),
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                  color: const Color(0xFFEDEFF3),
                  child: Stack(children: [
                    Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Row(children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text('Order in Progress',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600))
                            ]))),
                    const Positioned(
                        left: 40,
                        bottom: 90,
                        child: Icon(Icons.two_wheeler,
                            color: AppColors.blue, size: 26)),
                    const Positioned(
                        right: 30,
                        top: 90,
                        child: Icon(Icons.location_on,
                            color: AppColors.orange, size: 30)),
                    Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                    Text('Arriving in',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.ink500)),
                                    Text('15 min',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.navy))
                                  ])),
                              Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      color: AppColors.blueLight,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.timer_outlined,
                                      color: AppColors.blue, size: 18))
                            ]))),
                  ])))));
}

class _P3 extends StatelessWidget {
  const _P3();
  @override
  Widget build(BuildContext context) => _Scaf(
          child: Column(children: [
        const Align(alignment: Alignment.topRight, child: DottedGrid()),
        const SizedBox(height: 12),
        RichText(
            text: const TextSpan(
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                    letterSpacing: 1),
                children: [
              TextSpan(text: 'PELEKA'),
              TextSpan(text: '.', style: TextStyle(color: AppColors.orange))
            ])),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Text('YOUR ORDER',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                  letterSpacing: 2)),
          Text('  •  ',
              style: TextStyle(fontSize: 11, color: AppColors.orange)),
          Text('WE DELIVER',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                  letterSpacing: 2))
        ]),
        const Spacer(),
        Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.blueLight, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
                shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.delivery_dining,
                size: 130, color: AppColors.blue)),
        const Spacer(),
        const SizedBox(height: 12),
        const Text('Fast. Reliable. On Time.',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.navy)),
        const SizedBox(height: 6),
        const Text('Delivering happiness to your doorstep.',
            style: TextStyle(fontSize: 13, color: AppColors.ink500)),
        const SizedBox(height: 8),
      ]));
}
