import 'package:flutter/material.dart';
import 'translations.dart';

/// Shorthand accessor: S.of(context).key
class S {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _strings;

  AppLocalizations(this.locale);

  Future<void> load() async {
    final lang = locale.languageCode;
    _strings = translations[lang] ?? translations['en']!;
  }

  String _t(String key) => _strings[key] ?? translations['en']?[key] ?? key;

  // ── General ──
  String get appName => _t('appName');
  String get ok => _t('ok');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get delete => _t('delete');
  String get confirm => _t('confirm');
  String get error => _t('error');
  String get loading => _t('loading');
  String get retry => _t('retry');
  String get close => _t('close');
  String get back => _t('back');
  String get done => _t('done');
  String get share => _t('share');
  String get copy => _t('copy');
  String get search => _t('search');
  String get noResults => _t('noResults');
  String get success => _t('success');
  String get send => _t('send');
  String get apply => _t('apply');
  String get skip => _t('skip');

  // ── Navigation ──
  String get home => _t('home');
  String get explore => _t('explore');
  String get create => _t('create');
  String get messages => _t('messages');
  String get profile => _t('profile');
  String get notifications => _t('notifications');

  // ── Timeline / Posts ──
  String get translate => _t('translate');
  String get showOriginal => _t('showOriginal');
  String get like => _t('like');
  String get likes => _t('likes');
  String get comment => _t('comment');
  String get comments => _t('comments');
  String get viewAllComments => _t('viewAllComments');
  String get openInBrowser => _t('openInBrowser');
  String get copyLink => _t('copyLink');
  String get linkCopied => _t('linkCopied');
  String get translationFailed => _t('translationFailed');
  String get translationError => _t('translationError');
  String get apiKeyNotSet => _t('apiKeyNotSet');
  String get posts => _t('posts');
  String get followers => _t('followers');
  String get following => _t('following');

  // ── Story ──
  String get story => _t('story');
  String get stories => _t('stories');
  String get deleteStory => _t('deleteStory');
  String get deleteStoryConfirm => _t('deleteStoryConfirm');
  String get replyToStory => _t('replyToStory');
  String get replySent => _t('replySent');
  String get noViewersYet => _t('noViewersYet');
  String get viewers => _t('viewers');
  String get viewer => _t('viewer');
  String get noStories => _t('noStories');
  String get goBack => _t('goBack');
  String get imageUnavailable => _t('imageUnavailable');
  String get failedToLoadImage => _t('failedToLoadImage');
  String get publishingStory => _t('publishingStory');
  String get storyPublished => _t('storyPublished');
  String get storyFailed => _t('storyFailed');
  String get yourStory => _t('yourStory');
  String get addStory => _t('addStory');

  // ── Post Creation ──
  String get gallery => _t('gallery');
  String get camera => _t('camera');
  String get video => _t('video');
  String get aiEdit => _t('aiEdit');
  String get editWithAi => _t('editWithAi');
  String get aiIsWorking => _t('aiIsWorking');
  String get describeEdit => _t('describeEdit');
  String get imageEdited => _t('imageEdited');
  String get addCaption => _t('addCaption');
  String get publish => _t('publish');
  String get publishing => _t('publishing');

  // ── Search ──
  String get searchHint => _t('searchHint');
  String get searching => _t('searching');
  String get tryDifferentKeywords => _t('tryDifferentKeywords');
  String get findYourPeople => _t('findYourPeople');
  String get searchByUsername => _t('searchByUsername');

  // ── Notifications ──
  String get clearAll => _t('clearAll');
  String get clearAllConfirm => _t('clearAllConfirm');
  String get notificationsCleared => _t('notificationsCleared');
  String get cannotBeUndone => _t('cannotBeUndone');
  String get startedFollowing => _t('startedFollowing');
  String get likedYourPost => _t('likedYourPost');
  String get boostedYourPost => _t('boostedYourPost');
  String get mentionedYou => _t('mentionedYou');
  String get pollEnded => _t('pollEnded');
  String get postedNew => _t('postedNew');

  // ── Post Card ──
  String get viewAllCommentsCount => _t('viewAllComments');
  String get openInBrowserAction => _t('openInBrowser');
  String get copyLinkAction => _t('copyLink');
  String get linkCopiedMsg => _t('linkCopied');
  String get noPosts => _t('noPosts');
  String get loadMore => _t('loadMore');

  // ── Messages / DMs ──
  String get directMessages => _t('directMessages');
  String get newMessage => _t('newMessage');
  String get sendMessage => _t('sendMessage');
  String get typeMessage => _t('typeMessage');
  String get noConversations => _t('noConversations');

  // ── Profile ──
  String get editProfile => _t('editProfile');
  String get followRequests => _t('followRequests');
  String get follow => _t('follow');
  String get unfollow => _t('unfollow');
  String get block => _t('block');
  String get mute => _t('mute');
  String get report => _t('report');
  String get bookmarks => _t('bookmarks');
  String get likedPosts => _t('likedPosts');
  String get collections => _t('collections');
  String get archivedPosts => _t('archivedPosts');

  // ── Settings ──
  String get settings => _t('settings');
  String get appLanguage => _t('appLanguage');
  String get systemDefault => _t('systemDefault');
  String get translation => _t('translation');
  String get autoTranslateAll => _t('autoTranslateAll');
  String get translateProvider => _t('translateProvider');
  String get targetLanguage => _t('targetLanguage');
  String get about => _t('about');
  String get contentFilters => _t('contentFilters');
  String get mutedBlocked => _t('mutedBlocked');
  String get domainBlocks => _t('domainBlocks');
  String get aiCreativity => _t('aiCreativity');
  String get notificationSettings => _t('notificationSettings');
  String get logout => _t('logout');
  String get logoutConfirm => _t('logoutConfirm');
  String get version => _t('version');

  // ── Sub-pages ──
  String get editPost => _t('editPost');
  String get noCollections => _t('noCollections');
  String get pickCollection => _t('pickCollection');
  String get editHistory => _t('editHistory');
  String get noEditHistory => _t('noEditHistory');
  String get deleteMessage => _t('deleteMessage');
  String get newFilter => _t('newFilter');
  String get action => _t('action');
  String get applyTo => _t('applyTo');
  String get noContentFilters => _t('noContentFilters');
  String get blockDomain => _t('blockDomain');
  String get blockedDomains => _t('blockedDomains');
  String get noBlockedDomains => _t('noBlockedDomains');
  String get noMutedUsers => _t('noMutedUsers');
  String get noBlockedUsers => _t('noBlockedUsers');
  String get archive => _t('archive');
  String get noArchivedPosts => _t('noArchivedPosts');
  String get unarchive => _t('unarchive');
  String get restorePost => _t('restorePost');
  String get postRestored => _t('postRestored');
  String get emptyCollection => _t('emptyCollection');
  String get noPendingRequests => _t('noPendingRequests');
  String get allCaughtUp => _t('allCaughtUp');
  String get searchPeople => _t('searchPeople');

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  static const List<Locale> supportedLocales = [
    Locale('en'), Locale('fr'), Locale('es'), Locale('de'),
    Locale('it'), Locale('pt'), Locale('nl'), Locale('ru'),
    Locale('zh'), Locale('ja'), Locale('ko'), Locale('ar'),
    Locale('hi'), Locale('tr'), Locale('pl'), Locale('uk'),
  ];
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en','fr','es','de','it','pt','nl','ru','zh','ja','ko','ar','hi','tr','pl','uk']
          .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
