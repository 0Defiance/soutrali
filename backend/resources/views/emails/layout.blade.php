<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('subject', 'Soutrali')</title>
</head>
<body style="margin:0;padding:0;background-color:#FFF9F2;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#FFF9F2;padding:24px 12px;">
    <tr>
        <td align="center">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;background-color:#FFFFFF;border:1px solid #DCE5DF;border-radius:14px;overflow:hidden;">
                <tr>
                    <td style="background-color:#0B5A2A;padding:20px 28px;">
                        <span style="font-family:'Segoe UI',Arial,sans-serif;font-size:22px;font-weight:700;color:#FFFFFF;letter-spacing:0.5px;">Soutrali</span>
                        <span style="font-family:'Segoe UI',Arial,sans-serif;font-size:13px;color:#FE7402;">&nbsp;·&nbsp;L’entraide à porter de main</span>
                    </td>
                </tr>
                <tr>
                    <td style="padding:28px;font-family:'Segoe UI',Arial,sans-serif;font-size:15px;line-height:1.65;color:#1F2A24;">
                        @yield('body')
                    </td>
                </tr>
                <tr>
                    <td style="padding:18px 28px;background-color:#FFF9F2;border-top:1px solid #DCE5DF;font-family:'Segoe UI',Arial,sans-serif;font-size:12px;line-height:1.6;color:#5A6B62;">
                        Cet e-mail est envoyé automatiquement par Soutrali : merci de ne pas y répondre.<br>
                        © {{ date('Y') }} Soutrali — services et entraide à Abidjan.
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
