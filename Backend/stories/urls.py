from django.urls import path
from .views import (
    StoryFeedView,
    CookStoriesView,
    StoryCreateView,
    StoryDeleteView,
    MyStoriesView,
)

urlpatterns = [
    path('stories/', StoryCreateView.as_view(), name='story-create'),
    path('stories/feed/', StoryFeedView.as_view(), name='story-feed'),
    path('stories/my/', MyStoriesView.as_view(), name='my-stories'),
    path('stories/cook/<uuid:cook_id>/', CookStoriesView.as_view(), name='cook-stories'),
    path('stories/<uuid:pk>/', StoryDeleteView.as_view(), name='story-delete'),
]
