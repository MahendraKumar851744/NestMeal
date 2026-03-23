from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('meals', '0001_initial'),
    ]

    operations = [
        # Remove the old URLField
        migrations.RemoveField(
            model_name='mealimage',
            name='image_url',
        ),
        # Add the new ImageField
        migrations.AddField(
            model_name='mealimage',
            name='image',
            field=models.ImageField(upload_to='meal_images/', default=''),
            preserve_default=False,
        ),
        # Also update currency default from INR to AUD
        migrations.AlterField(
            model_name='meal',
            name='currency',
            field=models.CharField(
                choices=[('AUD', 'AUD'), ('INR', 'INR'), ('USD', 'USD'), ('EUR', 'EUR')],
                default='AUD',
                max_length=3,
            ),
        ),
    ]
