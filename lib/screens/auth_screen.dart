import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(register ? 'Create account' : 'Welcome back')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  register
                      ? 'Join your local lost & found community.'
                      : 'Sign in to manage reports and claims.',
                ),
                const SizedBox(height: 24),
                if (register) ...[
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) => v == null || v.length < 8
                      ? 'Use at least 8 characters'
                      : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: Text(
                    busy
                        ? 'Please wait…'
                        : register
                        ? 'Create account'
                        : 'Sign in',
                  ),
                ),
                if (!register) ...[Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _forgotPassword, child: const Text('Forgot password?'))), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _resetPassword, child: const Text('I have a reset token')))],
                TextButton(
                  onPressed: () => setState(() => register = !register),
                  child: Text(
                    register
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email=TextEditingController(text:this.email.text.trim()), token=TextEditingController(), password=TextEditingController(), confirm=TextEditingController();
    final key=GlobalKey<FormState>();
    final result=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Reset password'),content:Form(key:key,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextFormField(controller:email,decoration:const InputDecoration(labelText:'Email'),validator:(v)=>v==null||!v.contains('@')?'Enter a valid email':null),const SizedBox(height:12),TextFormField(controller:token,decoration:const InputDecoration(labelText:'Reset token'),validator:(v)=>v==null||v.trim().isEmpty?'Enter the token':null),const SizedBox(height:12),TextFormField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'New password'),validator:(v)=>v==null||v.length<8?'Use at least 8 characters':null),const SizedBox(height:12),TextFormField(controller:confirm,obscureText:true,decoration:const InputDecoration(labelText:'Confirm password'),validator:(v)=>v!=password.text?'Passwords do not match':null)]))),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>key.currentState!.validate()?Navigator.pop(context,true):null,child:const Text('Reset password'))]));
    if(result!=true)return;
    try{await context.read<AuthProvider>().resetPassword(email:email.text,token:token.text,password:password.text,confirmation:confirm.text);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Password reset successfully. You can now sign in.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e is ApiException?e.userMessage:e.toString())));}
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: email.text.trim());
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Reset password'), content: Form(key:key, child:TextFormField(controller:controller,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email'),validator:(v)=>v==null||!v.contains('@')?'Enter a valid email':null)), actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>key.currentState!.validate()?Navigator.pop(context,true):null,child:const Text('Send reset link'))]));
    if(ok!=true)return;
    try { await context.read<AuthProvider>().forgotPassword(controller.text); if(mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('If that email exists, a password reset link has been sent.'))); } }
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e is ApiException?e.userMessage:e.toString())));}
  }

  Future<void> _submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final auth = context.read<AuthProvider>();
      if (register) {
        await auth.register(name.text.trim(), email.text.trim(), password.text);
      } else {
        await auth.login(email.text.trim(), password.text);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.userMessage : e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
