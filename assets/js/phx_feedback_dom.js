import { isUsedInput } from "phoenix_live_view";

let resetFeedbacks = (container, feedbacks) => {
  feedbacks =
    feedbacks ||
    Array.from(container.querySelectorAll("[phx-feedback-for]")).map((el) => [
      el,
      el.getAttribute("phx-feedback-for"),
    ]);

  feedbacks.forEach(([feedbackEl, name]) => {
    let query = `[name="${name}"], [name="${name}[]"]`;
    let isUsed = Array.from(container.querySelectorAll(query)).find((input) =>
      isUsedInput(input)
    );
    if (isUsed || !feedbackEl.hasAttribute("phx-feedback-for")) {
      feedbackEl.classList.remove("phx-no-feedback");
    } else {
      feedbackEl.classList.add("phx-no-feedback");
    }
  });
};

export default function phxFeedbackDom(dom) {
  window.addEventListener("reset", (e) => resetFeedbacks(document));
  let feedbacks;
  let submitPending = false;
  let inputPending = false;
  window.addEventListener("submit", (e) => (submitPending = e.target));
  window.addEventListener("input", (e) => (inputPending = e.target));

  return {
    onPatchStart(container) {
      feedbacks = [];
      dom.onPatchStart && dom.onPatchStart(container);
    },
    onNodeAdded(node) {
      if (node.hasAttribute && node.hasAttribute("phx-feedback-for")) {
        feedbacks.push([node, node.getAttribute("phx-feedback-for")]);
      }
      dom.onNodeAdded && dom.onNodeAdded(node);
    },
    onBeforeElUpdated(from, to) {
      let fromFor = from.getAttribute("phx-feedback-for");
      let toFor = to.getAttribute("phx-feedback-for");
      if (fromFor || toFor) {
        feedbacks.push([from, fromFor || toFor], [to, toFor || fromFor]);
      }
      dom.onBeforeElUpdated && dom.onBeforeElUpdated(from, to);
    },
    onPatchEnd(container) {
      resetFeedbacks(container, feedbacks);
      if (inputPending || submitPending) {
        resetFeedbacks(container);
        inputPending = null;
        submitPending = null;
      }
      dom.onPatchEnd && dom.onPatchEnd(container);
    },
  };
}
