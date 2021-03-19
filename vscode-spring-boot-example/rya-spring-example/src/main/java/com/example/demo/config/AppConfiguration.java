package com.example.demo.config;

import org.apache.accumulo.core.client.AccumuloException;
import org.apache.accumulo.core.client.AccumuloSecurityException;
import org.apache.accumulo.core.client.Connector;
import org.apache.accumulo.core.client.ZooKeeperInstance;
import org.apache.accumulo.core.client.security.tokens.PasswordToken;
import org.apache.rya.accumulo.AccumuloRdfConfiguration;
import org.apache.rya.accumulo.AccumuloRyaDAO;
import org.apache.rya.rdftriplestore.RdfCloudTripleStore;
import org.apache.rya.rdftriplestore.RyaSailRepository;
import org.eclipse.rdf4j.repository.Repository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AppConfiguration {
  
  @Bean(destroyMethod = "shutDown")
  public Repository getRepository() throws AccumuloException, AccumuloSecurityException {
    final RdfCloudTripleStore store = new RdfCloudTripleStore();
    AccumuloRdfConfiguration conf = new AccumuloRdfConfiguration();
    AccumuloRyaDAO dao = new AccumuloRyaDAO();
    ZooKeeperInstance instance = new ZooKeeperInstance("dev", "rya");
    PasswordToken token = new PasswordToken("root");
    Connector connector = instance.getConnector("root", token);
    dao.setConnector(connector);
    conf.setTablePrefix("rya_");
    dao.setConf(conf);
    store.setRyaDAO(dao);

    Repository myRepository = new RyaSailRepository(store);
    myRepository.initialize();
    return myRepository;
  }
}
