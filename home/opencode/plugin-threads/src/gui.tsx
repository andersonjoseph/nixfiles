import { Schema } from "effect"
import { createComputed } from "solid-js"
import { Panel, Plugin, Slot, Store, Style, usePlugin, type MountedSession, type PanelTab } from "@opencode/plugin/gui"

const definition = Plugin.define({
  i18n: {
    en: {
      "button.label": "Thread Notes",
      "panel.title": "Thread Notes",
      "note.placeholder": "Write a note for this thread…",
    },
  },
  stores: {
    notes: Store.global(
      Schema.Struct({ bySession: Schema.Record(Schema.String, Schema.String) }),
      { bySession: {} },
    ),
  },
})

export default Plugin.define({
  ...definition,
  setup(ctx) {
    const ui = ctx.ui
    const tab: PanelTab = {
      id: "thread",
      get title() {
        return ctx.t("panel.title")
      },
    }

    ctx.add(Style, `.threads-note-wrap {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  padding: 8px;
}
.threads-note {
  flex: 1;
  width: 100%;
  resize: none;
  border: none;
  outline: none;
  background: transparent;
  color: inherit;
  font: inherit;
  padding: 0;
}`)

    createComputed(() => {
      for (const key of Object.keys(ctx.stores.notes.value.bySession)) {
        const [serverID, sessionID] = key.split("\n")
        const data = ctx.servers.get(serverID)?.data
        if (!data || data.session.missing(sessionID)) {
          ctx.stores.notes.update((draft) => {
            delete draft.bySession[key]
          })
        }
      }
    })

    ctx.add(Panel, {
      id: "thread",
      region: "side",
      list: (input) => (input.open.includes("thread") ? [tab] : []),
      render: (props) => <NoteEditor session={() => props.session} />,
    })

    ctx.add(Slot, {
      at: "session.header",
      render: (input) => (
        <ui.Tooltip value={ctx.t("button.label")} placement="bottom">
          <ui.IconButton
            icon="edit"
            label={ctx.t("button.label")}
            pressed={ctx.layout.state(`${ctx.id}:thread`, input.session) === "visible"}
            onClick={() => ctx.layout.toggle(`${ctx.id}:thread`, input.session)}
          />
        </ui.Tooltip>
      ),
    })
  },
})

function NoteEditor(props: { session: () => MountedSession }) {
  const ctx = usePlugin<typeof definition>()
  const text = () => ctx.stores.notes.value.bySession[props.session().key] ?? ""

  const write = (value: string) => {
    const session = props.session()
    const data = ctx.servers.get(session.server.id)?.data
    if (!data || data.session.missing(session.id)) return
    ctx.stores.notes.update((draft) => {
      draft.bySession[session.key] = value
    })
  }

  return (
    <div class="threads-note-wrap">
      <textarea
        class="threads-note"
        placeholder={ctx.t("note.placeholder")}
        value={text()}
        onInput={(e) => write(e.currentTarget.value)}
      />
    </div>
  )
}
