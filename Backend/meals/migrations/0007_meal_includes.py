from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('meals', '0006_default_avg_rating_5'),
    ]

    operations = [
        migrations.AddField(
            model_name='meal',
            name='includes',
            field=models.JSONField(blank=True, default=list, help_text='List of items included with the meal, e.g. ["onion", "lemon", "raita"]'),
        ),
    ]
