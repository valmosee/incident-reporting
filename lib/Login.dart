// ignore_for_file: file_names, prefer_const_constructors, no_leading_underscores_for_local_identifiers, use_key_in_widget_constructors, must_be_immutable, no_logic_in_create_state, override_on_non_overriding_member, unused_field, unused_element, sort_child_properties_last, avoid_print

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Login> {
  TextEditingController myUsername = TextEditingController();
  TextEditingController myPassword = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    if (Supabase.instance.client.auth.currentUser != null) {
      print("sudah login");
      final session = Supabase.instance.client.auth.currentSession;
      print("Access Token: ${session!.accessToken}");
      print("Refresh Token: ${session.refreshToken}");
      print("Expires At: ${session.expiresAt}");
      print("Token Type: ${session.tokenType}");

      final user = session.user;
      print("User ID: ${user.id}");
      print("Email: ${user.email}");
    } else {
      print("belum login");
    }
  }

  Future<void> evtlogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      print("Logout berhasil");
    } catch (e) {
      print("ERROR LOGOUT: $e");
    }
  }

  Future<void> evtlogin(String email, String password) async {
    print("start login");

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print("response: $response");

      if (response.session != null) {
        print("Login berhasil");
        print("User: ${response.user?.email}");
      } else {
        print("Login gagal (session null)");
      }
    } catch (e) {
      print("ERROR LOGIN: $e");
    }
  }

  Future<void> evtregister(String email, String password) async {
    print("start register");

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': "-", 'phone': '-', 'provider_type': 'user'},
      );

      print("response: $response");

      if (response.user != null) {
        print('Register berhasil');
      } else {
        print("Register gagal");
      }
    } catch (e) {
      print("ERROR REGISTER: $e");
    }
  }

  Future<void> evtTambahData() async {
    print("start insert");

    try {
      final response = await supabase.from('produk').insert({
        'name': 'Pensil',
        'stock': 10,
        'price': 10000,
        'status': 'Aktif',
      });

      print("response: $response");
    } catch (e) {
      print("ERROR INSERT: $e");
    }
  }

  Future<void> evtSelectProduk() async {
    print("start select produk");

    try {
      final response = await supabase.from('produk').select();

      // response = List<dynamic>
      List dataList = response;

      print(dataList);
    } catch (e) {
      print("ERROR INSERT: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: ListView(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 10.0),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 30, 10),
                  child: Center(
                    child: TextFormField(
                      controller: myUsername,
                      keyboardType: TextInputType.text,
                      autofocus: false,
                      decoration: InputDecoration(labelText: 'Username'),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 30, 10),
                  child: Center(
                    child: TextFormField(
                      controller: myPassword,
                      keyboardType: TextInputType.text,
                      autofocus: false,
                      decoration: InputDecoration(labelText: 'Password'),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 30, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          child: Text('Login User'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            // evtlogin(
                            //   "rajinkoding@gmail.com",
                            //   "mainananakkecil3",
                            // );
                            // evtlogout(context);
                            // evtTambahData();
                            evtSelectProduk();
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          child: Text('Register User'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            evtregister(
                              "widjajarn@gmail.com",
                              "mainananakkecil3",
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
