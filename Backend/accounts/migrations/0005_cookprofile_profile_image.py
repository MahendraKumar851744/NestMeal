from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0004_default_cook_avg_rating_5'),
    ]

    operations = [
        migrations.AddField(
            model_name='cookprofile',
            name='profile_image',
            field=models.ImageField(blank=True, null=True, upload_to='cook_profiles/'),
        ),
    ]
