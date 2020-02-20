import Turbolinks from 'turbolinks';

document.addEventListener('turbolinks:load', () => {
  const $input = $('.js-communities-collections-searchbox');

  if ($input.length > 0) {
    const maxItems = $input.data('max-items') || 5;

    const options = {
      adjustWidth: false,
      getValue: 'name',
      url(phrase) {
        // we use a relative url "communities.json" here as this will be used for both /admin and non admin (/) paths
        return `communities.json?search=${phrase}`;
      },
      categories: [
        {
          maxNumberOfElements: maxItems,
          listLocation: 'communities',
          header: '<strong>Communities</strong>',
        },
        {
          maxNumberOfElements: maxItems,
          listLocation: 'collections',
          header: '<strong>Collections</strong>',
        }
      ],
      list: {
        onChooseEvent() {
          const { url } = $input.getSelectedItemData();
          $input.val('');
          Turbolinks.visit(url);
        }
      }
    };

    $input.easyAutocomplete(options);
  }
});
