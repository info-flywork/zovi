part of '../phone_verified_view.dart';

class PhoneVerifiedBody extends StatelessWidget {
  const PhoneVerifiedBody({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Image.asset(
            AssetPaths.greenTick,
            width: 210,
            height: 140,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          const Text(
            'Numaran\ndoğrulandı 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.56,
              color: AppColors.deepRoast,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Zovi’ye hoş geldin. Etrafındaki\ndünya seni bekliyor.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 20 / 16,
              letterSpacing: -0.32,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: _VerificationStampCard(),
          ),
          const Spacer(),
          AppButton(label: 'Devam Et', onPressed: onContinue),
        ],
      ),
    );
  }
}

class _VerificationStampCard extends StatelessWidget {
  const _VerificationStampCard();

  static const _cardGradient = [Color(0xFFFF5C1A), Color(0xFFFF4D6D)];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: _cardGradient),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  AssetPaths.stickerBlueTick,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'İlk adım stamp’i kazandın:\nHesap Doğrulama',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.32,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Telefon numarası ile hesabın doğrulandı',
                      style: TextStyle(
                        color: Color(0xA6FFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1,
                        letterSpacing: -0.32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Positioned(top: -14, right: 10, child: _NewBadge()),
      ],
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
        decoration: BoxDecoration(
          color: AppColors.zoviOrange,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'New!',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -0.32,
          ),
        ),
      ),
    );
  }
}
