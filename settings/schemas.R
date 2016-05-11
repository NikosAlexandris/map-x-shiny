
mxConfig$schemas = list()




mxConfig$schemas$projectTree = list(
  title="Project",
  type="object",
  "$ref"="#/definitions/project",
  definitions=list(
    project=list(
      type="object",
      title="Project",
      properties=list(
        name=list(
          title="Project name",
          type="string"
          ),
        children=list(
          type="array",
          title="Sub projects",
          items=list(
            title="Sub project",
            "$ref"="#/definitions/project"
            )
          )
        )
      )
    )
  )



