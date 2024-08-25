from __future__ import annotations

import logging
import os

import click
import requests

LOG = logging.getLogger(__name__)


class Notify(object):
    def __init__(self, hook_url=None):
        # the optional explicit hook_url to use
        self.hook_url = hook_url
        # the env var containing the discord webhook to send messages to
        self.hook_env_var = "DISCORD_NOTIFY_HOOK_URL"

    def get_hook_url(self) -> str | None:
        if self.hook_url:
            return self.hook_url
        if self.hook_env_var:
            return os.environ.get(self.hook_env_var, "")

    def send_message(self, content: str | None = None, embeds: list | None = None) -> bool:
        hook_url = self.get_hook_url()
        if not hook_url:
            LOG.error(f"No hook url was set, check {self.hook_env_var}")
            return False

        if not content and not embeds:
            LOG.error("No content or embeds to send")
            return False

        json = {}
        if content:
            json["embeds"] = [{"title": content}]
        if embeds:
            json["embeds"] = embeds

        r = requests.post(hook_url, json=json)
        if r.status_code == 400:
            LOG.error("Error: %d: %s", r.status_code, r.reason)

        return r.status_code != 400


@click.command()
@click.argument("message", default="done")
def send_message(message: str):
    notify = Notify()
    notify.send_message(message)


if __name__ == "__main__":
    send_message()
