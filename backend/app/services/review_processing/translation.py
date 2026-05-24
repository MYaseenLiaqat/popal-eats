"""
Translation utilities — MarianMT-ready placeholder.

Target: store English translation for analytics when source is ur / roman_urdu.
"""

import logging

from app.config import get_settings

logger = logging.getLogger(__name__)

_marian_models: dict[str, object] = {}


def _load_marian_pair(source: str, target: str):
    settings = get_settings()
    if not settings.enable_marian_translation:
        return None

    key = f"{source}->{target}"
    if key in _marian_models:
        return _marian_models[key]
    try:
        from transformers import MarianMTModel, MarianTokenizer  # noqa: PLC0415

        model_name = f"Helsinki-NLP/opus-mt-{source}-{target}"
        logger.info("Loading MarianMT: %s", model_name)
        tok = MarianTokenizer.from_pretrained(model_name)
        model = MarianMTModel.from_pretrained(model_name)
        _marian_models[key] = (tok, model)
        return _marian_models[key]
    except Exception as exc:
        logger.debug("MarianMT not available (%s): %s", key, exc)
        return None


def translate_text(text: str, source_lang: str, target_lang: str | None = None) -> str:
    settings = get_settings()
    target = target_lang or settings.default_translation_target

    if not text.strip():
        return text
    if source_lang == target or source_lang in ("en", None):
        return text

    pair = _load_marian_pair(
        "ur" if source_lang == "roman_urdu" else source_lang,
        target,
    )
    if pair is not None:
        try:
            tok, model = pair
            batch = tok([text], return_tensors="pt", padding=True)
            gen = model.generate(**batch)
            return tok.decode(gen[0], skip_special_tokens=True)
        except Exception as exc:
            logger.warning("MarianMT inference failed: %s", exc)

    # Placeholder: prefix for pipeline testing without heavy models
    logger.debug("Translation placeholder %s -> %s", source_lang, target)
    return f"[{target}] {text}"
