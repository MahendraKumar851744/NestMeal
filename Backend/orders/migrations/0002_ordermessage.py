import uuid
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('orders', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='OrderMessage',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('sender_role', models.CharField(choices=[('customer', 'Customer'), ('cook', 'Cook')], max_length=10)),
                ('message', models.TextField(max_length=500)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('order', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='messages', to='orders.order')),
                ('sender', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='order_messages', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'order_messages',
                'ordering': ['created_at'],
            },
        ),
    ]
