from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.urls import path, include


def custom_404(request, exception):
    return JsonResponse({'detail': 'Not found.'}, status=404)


handler404 = custom_404

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/accounts/', include('accounts.urls')),
    path('api/', include('meals.urls')),
    path('api/', include('orders.urls')),
    path('api/', include('payments.urls')),
    path('api/', include('reviews.urls')),
    path('api/', include('coupons.urls')),
    path('api/', include('delivery.urls')),
    path('api/', include('notifications.urls')),
    path('api/', include('stories.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
