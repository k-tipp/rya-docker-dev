package com.example.demo.controller;

import org.eclipse.rdf4j.model.Model;
import org.eclipse.rdf4j.model.Statement;
import org.eclipse.rdf4j.repository.Repository;
import org.eclipse.rdf4j.repository.util.Repositories;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DemoController {

  @Autowired
  public Repository repo;
  
  @PostMapping("/demo")
  public void CreateDemo(Model model) {
    Repositories.consume(repo, conn -> {
      for(Statement stmt : model) {
        conn.add(stmt);
      }
    });
  }
}
