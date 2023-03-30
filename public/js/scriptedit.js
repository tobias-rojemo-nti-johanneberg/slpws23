const UNINCLUDED = 0;
const INCLUDED = 1;
const FEATURED = 2;

const SCRIPT_ID = document.querySelector(".character-list.script-edit")
  .attributes["data-script-id"].value;

document.querySelectorAll(".script-edit-character").forEach((character) => {
  const id = character.attributes["data-id"].value;
  const status = character.attributes["data-status"].value;
  const add = character.querySelector(".add");
  const remove = character.querySelector(".remove");
  const feature = character.querySelector(".feature");
  const unfeature = character.querySelector(".unfeature");
  if (status == UNINCLUDED) add.classList.add("show");
  if (status != UNINCLUDED) remove.classList.add("show");
  if (status == INCLUDED) feature.classList.add("show");
  if (status == FEATURED) unfeature.classList.add("show");
  add.addEventListener("click", () => {
    sendScriptEdit("add", id);
    add.classList.remove("show");
    remove.classList.add("show");
    feature.classList.add("show");
  });
  remove.addEventListener("click", () => {
    sendScriptEdit("remove", id);
    add.classList.add("show");
    remove.classList.remove("show");
    feature.classList.remove("show");
    unfeature.classList.remove("show");
  });
  feature.addEventListener("click", () => {
    sendScriptEdit("feature", id);
    feature.classList.remove("show");
    unfeature.classList.add("show");
  });
  unfeature.addEventListener("click", () => {
    sendScriptEdit("unfeature", id);
    feature.classList.add("show");
    unfeature.classList.remove("show");
  });
});

function sendScriptEdit(type, char_id) {
  let xhr = new XMLHttpRequest();
  xhr.open(
    "POST",
    `http://${document.location.host}/scripts/${SCRIPT_ID}/${type}/${char_id}`,
    true
  );
  xhr.setRequestHeader("content-type", "application/json");
  xhr.send();
}
