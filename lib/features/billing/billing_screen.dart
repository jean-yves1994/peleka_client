import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/peleka_card.dart';
import 'billing_repository.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(billingProvider);
    return Scaffold(backgroundColor: AppColors.bg, appBar: AppBar(title: const Text('Billing & history')), body: b.when(
      loading: ()=>const Center(child:CircularProgressIndicator(color:AppColors.orange)),
      error:(e,_)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('Could not load billing: $e'))),
      data:(x)=>RefreshIndicator(color:AppColors.orange,onRefresh:()=>ref.refresh(billingProvider.future),child:ListView(padding:const EdgeInsets.all(20),children:[
        if (x.isPremier) ...[
          PelekaCard(color:AppColors.navyLight,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Premier account',style:TextStyle(fontWeight:FontWeight.w800,fontSize:17,color:AppColors.navy)),
            const SizedBox(height:6),
            const Text('You can dispatch eligible shipments before payment. Your outstanding balance is billed later.',style:TextStyle(fontSize:12,color:AppColors.ink500,height:1.4)),
            const SizedBox(height:16),
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Outstanding',style:TextStyle(fontWeight:FontWeight.w700,color:AppColors.navy)),Text(money(x.outstandingBalance,currency:'RWF'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:20,color:AppColors.orange))]),
            if (x.creditLimit>0) ...[const SizedBox(height:6),Text('Credit limit: ${money(x.creditLimit,currency:'RWF')}',style:const TextStyle(fontSize:12,color:AppColors.ink500))]
          ])),const SizedBox(height:20),
        ],
        const Text('Shipment history',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:AppColors.navy)),
        const SizedBox(height:10),
        if (x.history.isEmpty) const PelekaCard(child:Padding(padding:EdgeInsets.all(18),child:Text('No shipment history yet.'))),
        ...x.history.map((s)=>Padding(padding:const EdgeInsets.only(bottom:10),child:PelekaCard(onTap:()=>context.push('/shipments/${s.id}'),child:Row(children:[
          const Icon(Icons.inventory_2_outlined,color:AppColors.blue),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(s.trackingNumber,style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.navy)),const SizedBox(height:3),Text('${s.status} · ${s.paymentStatus}',style:const TextStyle(fontSize:12,color:AppColors.ink500))])),Text(money(s.totalPrice,currency:s.currency),style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.navy))
        ])))),
      ]))));
  }
}
