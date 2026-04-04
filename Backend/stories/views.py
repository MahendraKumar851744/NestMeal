from django.utils import timezone
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser

from accounts.permissions import IsCook, IsCustomer
from .models import Story, StoryView
from .serializers import StorySerializer, StoryCreateSerializer


def _active_stories_qs():
    """Base queryset for non-expired, active stories."""
    return (
        Story.objects
        .select_related('cook')
        .filter(is_active=True, expires_at__gt=timezone.now())
    )


class StoryFeedView(generics.ListAPIView):
    """GET /stories/feed/ -- all active stories visible to any customer."""

    serializer_class = StorySerializer
    permission_classes = [IsAuthenticated, IsCustomer]

    def get_queryset(self):
        return _active_stories_qs()


class CookStoriesView(generics.ListAPIView):
    """GET /stories/cook/<id>/ -- active stories for a specific cook (public)."""

    serializer_class = StorySerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        cook_id = self.kwargs['cook_id']
        return _active_stories_qs().filter(cook_id=cook_id)


class StoryCreateView(generics.CreateAPIView):
    """POST /stories/ -- cook uploads a new story (image + optional caption)."""

    serializer_class = StoryCreateSerializer
    permission_classes = [IsAuthenticated, IsCook]
    parser_classes = [MultiPartParser, FormParser]


class StoryDeleteView(generics.DestroyAPIView):
    """DELETE /stories/<id>/ -- cook deletes own story."""

    serializer_class = StorySerializer
    permission_classes = [IsAuthenticated, IsCook]

    def get_queryset(self):
        return Story.objects.filter(cook=self.request.user.cook_profile)


class MyStoriesView(generics.ListAPIView):
    """GET /stories/my/ -- cook's own stories (all, including expired) for management."""

    serializer_class = StorySerializer
    permission_classes = [IsAuthenticated, IsCook]

    def get_queryset(self):
        return (
            Story.objects
            .select_related('cook')
            .prefetch_related('views')
            .filter(cook=self.request.user.cook_profile)
            .order_by('-created_at')
        )


class MarkStoryViewedView(generics.GenericAPIView):
    """POST /stories/<id>/view/ -- mark a story as viewed by the current customer."""

    permission_classes = [IsAuthenticated, IsCustomer]

    def post(self, request, pk):
        try:
            story = _active_stories_qs().get(pk=pk)
        except Story.DoesNotExist:
            return Response({'detail': 'Story not found.'}, status=status.HTTP_404_NOT_FOUND)
        StoryView.objects.get_or_create(story=story, customer=request.user)
        return Response({'detail': 'Marked as viewed.'}, status=status.HTTP_200_OK)
