from rest_framework import serializers
from .models import Story


class StorySerializer(serializers.ModelSerializer):
    cook_id = serializers.UUIDField(source='cook.id', read_only=True)
    cook_display_name = serializers.CharField(source='cook.display_name', read_only=True)
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Story
        fields = [
            'id', 'cook_id', 'cook_display_name',
            'image_url', 'caption',
            'created_at', 'expires_at', 'is_active',
        ]
        read_only_fields = ['id', 'created_at', 'expires_at', 'is_active']

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image and request:
            return request.build_absolute_uri(obj.image.url)
        return obj.image.url if obj.image else None


class StoryCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Story
        fields = ['image', 'caption']

    def create(self, validated_data):
        validated_data['cook'] = self.context['request'].user.cook_profile
        return super().create(validated_data)
