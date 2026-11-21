import 'dart:convert';
import 'package:scheldule/providers/auth/auth_provider.dart';
import 'package:scheldule/repositories/auth_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'package:scheldule/repositories/add_appointment_repository.dart';
import 'package:scheldule/providers/appointment/appointment_provider.dart';
import 'package:scheldule/screens/responsive_ui/mobile/appointments/appointments.dart';
import 'package:scheldule/screens/responsive_ui/settings/messaging_settings.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

void main() {
  for (final width in [360.0, 1440.0]) {
    testWidgets('Twilio walkthrough and owner credential form fit at $width', (tester) async {
      tester.view.physicalSize = Size(width, 800); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      Map<String,dynamic>? saved;
      final api=ApiClient(baseUrl:'http://localhost/api/v1',client:MockClient((request) async {
        if(request.method=='PUT') saved=jsonDecode(request.body) as Map<String,dynamic>;
        return http.Response(jsonEncode({'data':{'encryption_ready':true,'configured':false,'enabled':false,'reminder_hours':24}}),200);
      }));
      await tester.pumpWidget(Provider.value(value:api,child:MaterialApp(theme:buildAppTheme(Brightness.light),home:const Scaffold(body:MessagingSettings()))));
      await tester.pumpAndSettle();
      expect(find.text('Ρύθμιση βήμα προς βήμα'),findsOneWidget);
      await tester.scrollUntilVisible(find.byType(Form), 400);
      final fields=find.byType(CustomTextForm);
      for(final entry in <int,String>{0:'AC${'a'*32}',1:'SK${'b'*32}',2:'fixture-secret-123456789',3:'Physiocure'}.entries) {
        await tester.ensureVisible(fields.at(entry.key));
        await tester.enterText(find.descendant(of:fields.at(entry.key),matching:find.byType(TextFormField)),entry.value);
      }
      expect(tester.widget<CustomTextForm>(fields.at(2)).obscureText,true);
      final save=find.widgetWithText(FilledButton,'Αποθήκευση ρυθμίσεων');
      await tester.ensureVisible(save); await tester.tap(save); await tester.pumpAndSettle();
      expect(saved?['sender'],'Physiocure'); expect(saved?['api_secret'],'fixture-secret-123456789');
      expect(tester.widget<CustomTextForm>(fields.at(2)).controller!.text,isEmpty);
      expect(tester.takeException(),isNull);
    });
  }
  testWidgets('mobile appointment controls and list scroll together with short browser height', (tester) async {
    tester.view.physicalSize=const Size(360,600); tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final now=DateTime.now();
    final api=ApiClient(baseUrl:'http://localhost/api/v1',client:MockClient((request) async {
      Object data=[];
      if(request.url.path.endsWith('/availability')) data={'enabled':false};
      if(request.url.path.contains('/appointments')) { data=[for(var i=0;i<15;i++) {
        'uuid':'appointment-$i','client_id':'client-$i','client_record':{'first_name':'Customer $i','last_name':'Test'},
        'client':'Customer $i Test','start_time':DateTime(now.year,now.month,now.day,10).toIso8601String(),
        'end_time':DateTime(now.year,now.month,now.day,11).toIso8601String(),'paid':0,'total_price':30,
      }]; }
      return http.Response(jsonEncode({'data':data}),200);
    }));
    final repository=AppointmentRepository(apiClient:api);
    final provider=AppointmentProvider(appointmentRepository:repository);
    final auth=AuthProvider(authRepository:AuthRepository(apiClient:api));
    await tester.pumpWidget(MultiProvider(providers:[ChangeNotifierProvider.value(value:auth),Provider.value(value:api),Provider.value(value:repository),Provider(create:(_)=>AddAppointmentRepository(apiClient:api)),ChangeNotifierProvider.value(value:provider)],
      child:MaterialApp(theme:buildAppTheme(Brightness.light),home:Scaffold(body:NestedScrollView(headerSliverBuilder:(context,inner)=>[const SliverToBoxAdapter(child:SizedBox(height:90,child:Text("Page header")))],body:const Appointments())))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ιστορικό')); await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
    final headerY=tester.getTopLeft(find.text('Ιστορικό')).dy;
    await tester.drag(find.byType(SingleChildScrollView).first,const Offset(0,-450)); await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Ιστορικό')).dy,lessThan(headerY));
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox()); provider.dispose(); auth.dispose();
  });
}
