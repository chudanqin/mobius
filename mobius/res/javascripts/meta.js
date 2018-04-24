var meta = document.createElement('meta');
meta.setAttribute('name', 'viewport');
meta.setAttribute('content', 'width=device-width');
document.getElementsByTagName('head')[0].appendChild(meta);

var $img = document.getElementsByTagName('img');
for (var p in $img) {
    $img[p].style.width = '100%%';
    $img[p].style.height ='auto';
}
