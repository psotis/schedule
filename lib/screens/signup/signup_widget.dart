import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../providers/sign_up/signup_state.dart';
import '../../repositories/api_client.dart';

class SignupWidget extends StatefulWidget {
  final bool isMobile;
  SignupWidget({super.key, required this.isMobile});

  @override
  State<SignupWidget> createState() => _SignupWidgetState();
}

class _SignupWidgetState extends State<SignupWidget> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStoreTypes());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool check = false;
  bool obscureText = true;
  bool _loadingStoreTypes = true;
  String? _storeTypesError;
  String? _selectedStoreType;
  List<Map<String, dynamic>> _storeTypes = [];

  Future<void> _loadStoreTypes() async {
    setState(() {
      _loadingStoreTypes = true;
      _storeTypesError = null;
    });
    try {
      final response = await context.read<ApiClient>().get('/store-types');
      final storeTypes = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _storeTypes = storeTypes;
        _selectedStoreType = storeTypes.length == 1
            ? storeTypes.first['code']?.toString()
            : null;
        _loadingStoreTypes = false;
        if (storeTypes.isEmpty) {
          _storeTypesError = 'No store types are available';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingStoreTypes = false;
        _storeTypesError = 'Could not load store types';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var signupStatus = context.watch<SignupProvider>().state.signupStatus;
    return Column(
      spacing: 15,
      children: [
        //* ****************** Name textfield ***************************
        SizedBox(
          // height: ScreenSize.screenHeight * .1,
          width: double.infinity,
          child: TextFormField(
            style: const TextStyle(color: Color(0xFF14213D)),
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              floatingLabelStyle: const TextStyle(height: 1.2),
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                size: widget.isMobile == true ? 18 : 22,
              ),
            ),
            onChanged: (value) {
              value = _emailController.text;
            },
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: _loadingStoreTypes
              ? const Center(child: CircularProgressIndicator())
              : _storeTypesError != null
                  ? OutlinedButton.icon(
                      onPressed: _loadStoreTypes,
                      icon: const Icon(Icons.refresh),
                      label: Text(_storeTypesError!),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _selectedStoreType,
                      decoration: InputDecoration(
                        labelText: 'Business type',
                        floatingLabelStyle: const TextStyle(height: 1.2),
                        prefixIcon: Icon(
                          Icons.storefront_outlined,
                          size: widget.isMobile == true ? 18 : 22,
                        ),
                      ),
                      items: _storeTypes
                          .map(
                            (storeType) => DropdownMenuItem<String>(
                              value: storeType['code']?.toString(),
                              child: Text(storeType['name']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedStoreType = value);
                      },
                    ),
        ),

        //* ****************** Email textfield ***************************
        SizedBox(
          // height: ScreenSize.screenHeight * .1,
          width: double.infinity,
          child: TextFormField(
            style: const TextStyle(color: Color(0xFF14213D)),
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'E-mail',
              floatingLabelStyle: const TextStyle(height: 1.2),
              prefixIcon: Icon(
                Icons.email_outlined,
                size: widget.isMobile == true ? 18 : 22,
              ),
            ),
            onChanged: (value) {
              value = _emailController.text;
            },
          ),
        ),

        //* ****************** Password textfield ***************************
        SizedBox(
          // height: ScreenSize.screenHeight * .1,
          width: double.infinity,
          child: TextFormField(
            style: const TextStyle(color: Color(0xFF14213D)),
            controller: _passwordController,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: 'Password',
              floatingLabelStyle: const TextStyle(height: 1.2),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                size: widget.isMobile == true ? 18 : 22,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() {
                  obscureText = !obscureText;
                }),
                icon: Icon(
                  obscureText == true
                      ? Icons.visibility_off
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            onChanged: (value) {
              value = _passwordController.text;
            },
          ),
        ),
        // SizedBox(height: ScreenSize.screenHeight * .02),
        SizedBox(
          height: 50,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: signupStatus == SignupStatus.submitting ? null : signUp,
            icon: signupStatus == SignupStatus.submitting
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(
              signupStatus == SignupStatus.submitting
                  ? 'Δημιουργία...'
                  : 'Δημιουργία λογαριασμού',
              style: TextStyle(
                fontSize: widget.isMobile == true ? 16 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // SizedBox(height: ScreenSize.screenHeight * .02),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.read<ChangePageProvider>().changePage(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text('Πίσω στη σύνδεση',
                style: TextStyle(
                  fontSize: widget.isMobile == true ? 16 : 18,
                )),
          ),
        ),
      ],
    );
  }

  Future signUp() async {
    if (_selectedStoreType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your business type')),
      );
      return;
    }
    try {
      await context.read<SignupProvider>().signup(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            storeType: _selectedStoreType!,
          );
    } catch (_) {
      if (!mounted) return;
      final error = context.read<SignupProvider>().state.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}
