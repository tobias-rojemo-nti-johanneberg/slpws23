document.querySelectorAll(".character").forEach((character) => {
  const type = character.getElementsByClassName("type")[0].innerHTML;
  character.getElementsByClassName("name")[0].classList.add(type);
});

document.querySelectorAll(".tag").forEach((tag) => {
  tag.style.backgroundColor = tag.attributes["data-bg"].value;
  tag.getElementsByClassName("tag-content")[0].style.color = tag.attributes["data-text"].value;
});
