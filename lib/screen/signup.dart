import 'package:chitchat/colors.dart';
import 'package:chitchat/screen/loginPage.dart';
import 'package:flutter/material.dart';

class signUp extends StatefulWidget {
  @override
  State<signUp> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<signUp> {
  var showPassword = true;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: mq.width,
            height: mq.height,
            color: !isDarkMode ? kPrimaryColor : kContentColorDarkTheme,
            child: Padding(
              padding: EdgeInsets.only(top: mq.height*0.04, left: 20),
              child: Text(
                'Sign Up\nCreate Your Account',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: kContentColorLightTheme,
                  fontWeight: FontWeight.bold,
                  fontSize: mq.width * 0.08,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top:mq.height * 0.18<0?0:mq.height*0.18),
            child: Container(
              width: mq.width,
              height: mq.height*0.8<0?0:mq.height*0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                // BorderRadius.only(
                //   topLeft: Radius.circular(20),
                //   topRight: Radius.circular(20),
                // ),
                color: isDarkMode ? Colors.black45 : kContentColorLightTheme,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(top: 30, left: 16, right: 16),
                  child: Form(
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: "Username",
                            suffixIcon: Icon(Icons.supervised_user_circle_outlined,
                                color:
                                isDarkMode ? Colors.white : Colors.black),
                          ),
                        ),
                        SizedBox(height: 30), // Add spacing
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: "Email",
                            suffixIcon: Icon(Icons.email_outlined,
                                color:
                                isDarkMode ? Colors.white : Colors.black),
                          ),
                        ),
                        const SizedBox(height: 30,),
                        TextFormField(
                          obscureText: showPassword, // Hide input for password
                          decoration: InputDecoration(
                            labelText: "Password",
                            suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                                icon: Icon(
                                  !showPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color:
                                  isDarkMode ? Colors.white : Colors.black,
                                )),
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          obscureText: showPassword, // Hide input for password
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                                icon: Icon(
                                  !showPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color:
                                  isDarkMode ? Colors.white : Colors.black,
                                )),
                          ),
                        ),
                        SizedBox(height: 24), // Add spacing
                        ElevatedButton(
                          onPressed: () {
                            // Implement login action
                          },
                          child: Center(
                              child: Text(
                                'Sign Up',
                                style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  color: isDarkMode
                                      ? kContentColorDarkTheme
                                      : kContentColorLightTheme,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                        ),
                        SizedBox(
                          height: mq.height *0.03,
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                  color: isDarkMode
                                      ? kContentColorLightTheme
                                      : kPrimaryColor,
                                )),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 5),
                              child: Text('Or SignUp with'),
                            ),
                            Expanded(
                                child: Divider(
                                  color: isDarkMode
                                      ? kContentColorLightTheme
                                      : kPrimaryColor,
                                ))
                          ],
                        ),
                        SizedBox(
                          height: mq.height * 0.008<0?0:mq.height * 0.008,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              splashColor: isDarkMode?Colors.white:Colors.grey,
                              onTap: (){},
                              child: Image(width: 25,image:AssetImage('assets/icon/google.png',)),
                            ),
                            InkWell(
                              child: CircleAvatar(
                                  child: Image(width: 30,image:AssetImage('assets/icon/facebook.png',)),
                                  backgroundColor: Colors.transparent
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: mq.height * 0.1<0?0:mq.height * 0.1,
                        ),
                        Align(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text("Already Have A Account?"),
                                SizedBox(width: 5,),
                                InkWell(
                                  onTap: (){
                                    Navigator.push(context,MaterialPageRoute(builder: (context)=>loginPage()));
                                  },
                                  child: Text(
                                    "Login In",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                        color: kPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                )
                              ]),
                          alignment: Alignment.bottomRight,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
