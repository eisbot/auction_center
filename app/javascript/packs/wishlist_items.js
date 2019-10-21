import * as punycode from 'punycode';

function formHandler() {
    const domainNameField = document
        .getElementById('wishlist_item_domain_name');
    domainNameField.value = punycode.toUnicode(domainNameField.value);
}

function createListItem(string, document) {
    const listItem = document.createElement('li');
    listItem.innerHTML = string;
    return listItem;
};

function onlyUnique(value, index, self) {
    return self.indexOf(value) === index;
}

document.body.addEventListener('ajax:error', (event) => {
    const xhr = event.detail[0];

    const errorsBlock = document.getElementById('errors');
    const errorsList = document.getElementById('errors-list');

    const uniqueMessages = xhr.filter(onlyUnique);

    uniqueMessages.forEach(function(message) {
        const listItem = createListItem(message, document);
        errorsList.appendChild(listItem);
    });

    errorsBlock.classList.remove('hidden');
});

document.addEventListener('ajax:beforeSend', (event) => {
    const errorsBlock = document.getElementById('errors');
    const errorsList = document.getElementById('errors-list');

    errorsBlock.classList.add('hidden');

    while (errorsList.firstChild) {
        errorsList.removeChild(errorsList.firstChild);
    }
});

document.addEventListener('turbolinks:load', (event) => {
    const form = document.getElementById('wishlist_item_form');
    const button = document.getElementById('wishlist_item_form_commit');

    form.addEventListener('change', formHandler);
    button.addEventListener('click', formHandler);
});
