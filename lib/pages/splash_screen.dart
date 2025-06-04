import 'package:flutter/material.dart';
import 'package:my_app/pages/home.dart';
import 'package:my_app/pages/login_screen.dart';


 class splashScreen extends StatefulWidget {
   const splashScreen({super.key});

   @override
   State<splashScreen> createState() => _splashScreenState();
 }

 class _splashScreenState extends State<splashScreen> {
   @override
   void initState(){
     super.initState();
     Future.delayed( Duration(seconds : 3),(){
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UniversityListScreen()));
     });
   }
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       backgroundColor: Colors.white,
         body: Center(
           child: Container(
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Image.asset("assets/images/logo.png",
                   height: 220,
                   width: 260,),
                 SizedBox(height: 40,),
                 CircularProgressIndicator(
                   strokeWidth: 4.5,
                 ),
               ],
             ),
           ),
         ),
       );
   }
 }
