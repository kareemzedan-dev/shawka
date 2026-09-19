import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';

/// نصوص قانونية موحّدة للويب.
abstract final class TarfaLegalContent {
  static const aboutTitle = 'من نحن';

  static String get aboutBody => '''
مرحبًا بك في ${AppBranding.shortName}، منصتك الذكية للطلب من موردي المواد الغذائية وشركات التوريد المحلية بكل سهولة وسرعة.

نعمل على ربط العملاء بأفضل المتاجر القريبة منهم، مع توفير تجربة طلب سلسة، وتتبع مباشر للطلبات، ووسائل دفع آمنة، وخدمة توصيل موثوقة.

نسعى دائمًا لتقديم خدمة تجمع بين السرعة، الجودة، والراحة، مع دعم المتاجر المحلية وتوفير أفضل تجربة للمستخدم في جميع أنحاء مصر.

${AppBranding.shortName}... كل اللي تحتاجه، يوصلك.''';

  static const privacyTitle = 'سياسة الخصوصية';

  static String get privacyBody => '''
نحن في ${AppBranding.shortName} نحترم خصوصية مستخدمينا ونلتزم بحماية بياناتهم الشخصية.

المعلومات التي نجمعها
• الاسم ورقم الهاتف والبريد الإلكتروني (إن وجد).
• عنوان التوصيل والموقع الجغرافي عند استخدام الخدمة.
• بيانات الطلبات وسجل العمليات.
• معلومات الدفع، ولا نقوم بالاحتفاظ ببيانات البطاقات البنكية، حيث تتم معالجتها بشكل آمن عبر مزود الدفع المعتمد.

استخدام البيانات
نستخدم بياناتك من أجل:
• تنفيذ وإدارة الطلبات.
• معالجة عمليات الدفع.
• تحسين جودة الخدمة.
• التواصل معك بشأن طلباتك أو الدعم الفني.
• إرسال الإشعارات المتعلقة بالخدمة.

مشاركة البيانات
قد تتم مشاركة البيانات الضرورية فقط مع:
• المتاجر ومقدمي الخدمات.
• شركات التوصيل.
• مزود الدفع الإلكتروني.
• الجهات المختصة إذا تطلب القانون ذلك.

حماية البيانات
نستخدم وسائل وتقنيات أمنية مناسبة لحماية بيانات المستخدمين ومنع الوصول غير المصرح به.

حقوق المستخدم
يمكنك طلب تحديث أو حذف بياناتك أو التواصل معنا لأي استفسار يتعلق بالخصوصية من خلال وسائل التواصل داخل التطبيق.

باستخدامك لتطبيق ${AppBranding.shortName} فإنك توافق على سياسة الخصوصية هذه.''';

  static const termsTitle = 'الشروط والأحكام';

  static String get termsBody => '''
باستخدامك لتطبيق ${AppBranding.shortName} فإنك توافق على الشروط التالية:

استخدام الخدمة
• يجب تقديم بيانات صحيحة عند إنشاء الحساب.
• يتحمل المستخدم مسؤولية الحفاظ على سرية حسابه.

الطلبات
• يعتمد تنفيذ الطلب على توفر المنتجات وخدمة التوصيل.
• يمكن رفض أو إلغاء بعض الطلبات وفقًا لسياسة المتجر أو لأسباب تشغيلية.

الدفع
• يدعم التطبيق الدفع الإلكتروني عبر مزود دفع معتمد بالإضافة إلى وسائل الدفع المتاحة.
• تتم جميع عمليات الدفع وفقًا لشروط مزود خدمة الدفع.
• قد يتم رد المبالغ المستحقة وفقًا لسياسة الاسترجاع المعمول بها.

الأسعار
الأسعار والرسوم المعروضة داخل التطبيق قابلة للتغيير من قبل المتاجر أو إدارة التطبيق دون إشعار مسبق.

الإلغاء والاسترجاع
تخضع عمليات الإلغاء والاسترجاع لسياسة المتجر وطبيعة الطلب، وقد تختلف من طلب لآخر.

المسؤولية
يبذل تطبيق ${AppBranding.shortName} أقصى جهد لضمان جودة الخدمة، إلا أنه لا يتحمل المسؤولية عن أي تأخير أو ظروف خارجة عن الإرادة.

تعديل الشروط
يحق لإدارة التطبيق تعديل هذه الشروط في أي وقت، ويعتبر استمرار استخدام التطبيق موافقة على التعديلات.''';

  static const refundTitle = 'سياسة الاسترجاع والاسترداد';

  static String get refundBody => '''
نظرًا لطبيعة المنتجات والخدمات المقدمة عبر ${AppBranding.shortName}، فإن جميع الطلبات تعتبر نهائية بعد تأكيدها، ولا نوفر خدمة إرجاع أو استبدال أو استرداد للمبالغ بعد إتمام الطلب.

في حال وجود مشكلة في الطلب، مثل:

• استلام طلب غير مطابق.
• نقص في المنتجات.
• تلف واضح في الطلب.
• عدم استلام الطلب.

يرجى التواصل مع فريق الدعم عبر التطبيق، وسيتم مراجعة الحالة والتنسيق مع المتجر أو مزود الخدمة لاتخاذ الإجراء المناسب عند استحقاق ذلك.

يحتفظ ${AppBranding.shortName} بحقه في دراسة كل حالة على حدة، ولا يضمن قبول طلبات الاسترداد أو التعويض إلا في الحالات التي يثبت فيها وجود خطأ أو مشكلة تستوجب ذلك.''';
}

/// يعرض نصًا قانونيًا في sheet قابل للتمرير.
Future<void> showTarfaLegalSheet(
  BuildContext context, {
  required String title,
  required String body,
}) {
  final isWide =
      MediaQuery.sizeOf(context).width >= TarfaTokens.tabletBreakpoint;

  if (isWide) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: TarfaTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
          child: _LegalSheetBody(title: title, body: body, onClose: () => Navigator.pop(ctx)),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: TarfaTokens.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _LegalSheetBody(
            title: title,
            body: body,
            scrollController: scrollController,
            onClose: () => Navigator.pop(ctx),
          ),
        );
      },
    ),
  );
}

class _LegalSheetBody extends StatelessWidget {
  const _LegalSheetBody({
    required this.title,
    required this.body,
    required this.onClose,
    this.scrollController,
  });

  final String title;
  final String body;
  final VoidCallback onClose;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TarfaTokens.headlineMedium(context),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Text(
                body.trim(),
                style: TarfaTokens.bodyLarge(context).copyWith(height: 1.7),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
