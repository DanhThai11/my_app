import 'package:flutter/material.dart';
import 'package:my_app/pages/cart.dart';

class checkout extends StatelessWidget {
  const checkout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Thanh toán',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w500
        ),)),
      ),
      body: Padding(
        padding: EdgeInsets.only(left: 10,top: 10
        ),
        child: Container(
          height: 700,
          width: 390,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow:[
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: Offset(0,3),
                  blurRadius: 9,
                  spreadRadius: 8,
                )
              ]
          ),
          child: Column(
            children: [
              SizedBox(height: 15,),
              cart4(),
              SizedBox(height: 25,),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow:[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: Offset(0,3),
                        blurRadius: 9,
                        spreadRadius: 8,
                      )
                    ]
                ),
                height: 415,
                width: 366,

                child: Padding(
                  padding: const EdgeInsets.only(left: 15,top: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng tiền sản phẩm:                       140.000 đ',style: TextStyle(
                        fontSize: 17
                      ),),
                      SizedBox(height: 8,),
                      Text('Phí vận chuyển:                                 22.000 đ',style: TextStyle(fontSize: 17),),
                      SizedBox(height: 8,),
                      Text('Phí dịch vụ:                                        10.000 đ',style: TextStyle(fontSize: 17),),
                      SizedBox(height: 8,),
                      Text('Thành tiền:              172.000 đ',style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                      ),),
                      SizedBox(height: 15,),
                      Container(color: Colors.black,
                      width: 330,height: 1,),
                      SizedBox(height: 15,),
                      Text('Phương thức thanh toán: ',style: TextStyle(fontWeight: FontWeight.w500,
                      fontSize: 23),),
                      SizedBox(height: 4,),
                      Text('-Thanh toán khi nhận hàng: ',style: TextStyle(
                          fontSize: 16),),
                      SizedBox(height: 12,),
                      Text('Địa chỉ giao hàng: ',style: TextStyle(fontWeight: FontWeight.w500,
                          fontSize: 23),),
                      SizedBox(height: 6,),
                      Text('Chí Hào: ',style: TextStyle(fontWeight: FontWeight.w500,
                          fontSize: 18),),
                      SizedBox(height: 6,),
                      Row(
                        children: [
                          Icon(Icons.phone),
                          SizedBox(width: 10,),
                          Text('+84 932586447',style: TextStyle(fontSize: 17),)
                        ],
                      ),
                      SizedBox(height: 6,),
                      Row(
                        children: [
                          Icon(Icons.person),
                          SizedBox(width: 10,),
                          Text('256 Lê Văn Sĩ, Phường 12, Quận Tân ',style: TextStyle(fontSize: 17),),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: Text('Bình, TP. Hồ Chí Minh',style: TextStyle(fontSize: 17),),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15,),
              Container(
                height: 60,
                width: 360,
                child: FloatingActionButton(onPressed: (){},
                  backgroundColor: Colors.green,
                child: Text('Thanh toán',
                style: TextStyle(color: Colors.white,
                fontSize: 25),),),
              )
            ],
          ),
        ),
      ),
    );
  }
}
class cart4 extends StatelessWidget {
  const cart4({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 150,
        width: 360,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0,3),
              blurRadius: 9,
              spreadRadius: 2,
            ),
          ],
        ),
        child:Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 13),
              child: Image.asset("assets/images/buoi.png",
                height: 120,
                width: 110,
                fit: BoxFit.fill,),

            ),
            SizedBox(width: 11,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 14,),
                Text('Bưởi da xanh', style: TextStyle(fontSize: 25,),),
                Text('Giá : 35.000 / kg', style: TextStyle(fontSize: 17),),
                SizedBox(height: 22,),
                Row(
                  children: [
                    Text('X',style: TextStyle(fontSize: 20),),
                    SizedBox(width: 3,),
                    Text('4',style: TextStyle(fontSize: 25),),
                    SizedBox(width: 72,),
                    Text('140.000 đ',style: TextStyle(fontSize: 25,
                    color: Colors.red),),
                  ],
                )
              ],
            )
          ],
        )
    );
  }
}